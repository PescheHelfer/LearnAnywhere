import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:learn_anywhere_core/core.dart';

import '../i18n/learn_anywhere_localizations.dart';
import '../theme/learn_anywhere_tokens.dart';
import 'help_content.dart';

/// Renders the bundled user guide: a contents list and a search box beside the
/// rendered chapter.
///
/// Lives in ui_kit, next to the chapter assets, so the desktop and the mobile
/// shell show the same guide. The layout collapses to one column on a narrow
/// surface, which is what the Android shell will get.
final class HelpViewer extends StatefulWidget {
  /// Creates the user guide viewer.
  const HelpViewer({super.key});

  /// Width below which the contents list and the chapter share one column
  /// instead of sitting side by side.
  static const double narrowBreakpoint = 720;

  /// Width of the contents pane in the side-by-side layout.
  static const double sidebarWidth = 260;

  @override
  State<HelpViewer> createState() => _HelpViewerState();
}

final class _HelpViewerState extends State<HelpViewer> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _chapterScrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  HelpLibrary? _library;
  String? _loadedLanguage;
  String? _selectedFileName;
  String _query = '';
  bool _showChapterOnNarrow = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode != _loadedLanguage) {
      _loadedLanguage = languageCode;
      unawaited(_load(languageCode));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chapterScrollController.dispose();
    super.dispose();
  }

  Future<void> _load(String languageCode) async {
    final HelpLibrary library = await HelpLibrary.load(
      DefaultAssetBundle.of(context),
      languageCode: languageCode,
    );
    if (!mounted || languageCode != _loadedLanguage) {
      return;
    }
    setState(() {
      _library = library;
      // Keep the reader on the same chapter across a language switch; the file
      // names are identical in every language folder.
      if (library.chapterByFileName(_selectedFileName ?? '') == null) {
        _selectedFileName = library.chapters.isEmpty
            ? null
            : library.chapters.first.fileName;
      }
    });
  }

  void _selectChapter(String fileName, {String? anchor}) {
    setState(() {
      _selectedFileName = fileName;
      _showChapterOnNarrow = true;
    });
    if (anchor == null || anchor.isEmpty) {
      _scrollChapterToTop();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? target = _sectionKeys[anchor]?.currentContext;
      if (target == null) {
        _scrollChapterToTop();
        return;
      }
      unawaited(
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 200),
          alignment: 0.05,
        ),
      );
    });
  }

  void _scrollChapterToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chapterScrollController.hasClients) {
        _chapterScrollController.jumpTo(0);
      }
    });
  }

  /// Follows a link tapped inside a chapter.
  ///
  /// Guide-internal links (`03-managing-files.md`, `#anchor`, or both) navigate
  /// in place. Anything else is offered for copying instead of being opened:
  /// the app deliberately has no URL launcher, so a chapter never depends on a
  /// browser being present.
  void _onTapLink(String? href) {
    final HelpLibrary? library = _library;
    if (href == null || href.isEmpty || library == null) {
      return;
    }
    final int hash = href.indexOf('#');
    final String file = hash < 0 ? href : href.substring(0, hash);
    final String anchor = hash < 0 ? '' : href.substring(hash + 1);

    if (file.isEmpty) {
      _selectChapter(_selectedFileName!, anchor: anchor);
      return;
    }
    if (library.chapterByFileName(file) != null) {
      _selectChapter(file, anchor: anchor);
      return;
    }
    unawaited(_showLinkDialog(href));
  }

  Future<void> _showLinkDialog(String href) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.helpLinkTitle)),
          content: SelectableText(href),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                unawaited(Clipboard.setData(ClipboardData(text: href)));
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                messages.message(LearnAnywhereMessage.helpCopyLink),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                messages.message(LearnAnywhereMessage.actionClose),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final HelpLibrary? library = _library;

    if (library == null) {
      // Deliberately blank rather than a spinner: the chapters are local
      // assets, so this frame is over before it can be seen — and an
      // indefinite progress animation never lets `pumpAndSettle` settle, which
      // would hang every widget test that opens this screen.
      return Material(color: colorScheme.surface);
    }
    if (library.isEmpty) {
      return Material(
        child: Center(
          child: Text(
            messages.message(LearnAnywhereMessage.helpUnavailable),
          ),
        ),
      );
    }

    return Material(
      color: colorScheme.surface,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool narrow =
              constraints.maxWidth < HelpViewer.narrowBreakpoint;
          if (!narrow) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  width: HelpViewer.sidebarWidth,
                  child: _buildSidebar(library, messages, narrow: false),
                ),
                VerticalDivider(
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(child: _buildChapter(library, messages)),
              ],
            );
          }
          return _showChapterOnNarrow
              ? _buildChapter(library, messages, showBack: true)
              : _buildSidebar(library, messages, narrow: true);
        },
      ),
    );
  }

  Widget _buildSidebar(
    HelpLibrary library,
    LearnAnywhereLocalizations messages, {
    required bool narrow,
  }) {
    final List<HelpSearchHit> hits = _query.isEmpty
        ? const <HelpSearchHit>[]
        : library.search(_query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: const OutlineInputBorder(),
              hintText: messages.message(LearnAnywhereMessage.helpSearchHint),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (String value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? _buildContentsList(library, messages, narrow: narrow)
              : _buildSearchResults(hits, messages),
        ),
      ],
    );
  }

  Widget _buildContentsList(
    HelpLibrary library,
    LearnAnywhereLocalizations messages, {
    required bool narrow,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      itemCount: library.chapters.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              LearnAnywhereTokens.gapMedium,
              0,
              LearnAnywhereTokens.gapMedium,
              LearnAnywhereTokens.gapSmall,
            ),
            child: Text(
              messages.message(LearnAnywhereMessage.helpContents),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
        }
        final HelpChapter chapter = library.chapters[index - 1];
        return ListTile(
          dense: true,
          selected: !narrow && chapter.fileName == _selectedFileName,
          title: Text(chapter.title),
          onTap: () => _selectChapter(chapter.fileName),
        );
      },
    );
  }

  Widget _buildSearchResults(
    List<HelpSearchHit> hits,
    LearnAnywhereLocalizations messages,
  ) {
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
        child: Text(messages.message(LearnAnywhereMessage.helpNoResults)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
      itemCount: hits.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              LearnAnywhereTokens.gapMedium,
              0,
              LearnAnywhereTokens.gapMedium,
              LearnAnywhereTokens.gapSmall,
            ),
            child: Text(
              messages
                  .message(LearnAnywhereMessage.helpMatchCount)
                  .replaceAll('{count}', '${hits.length}'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
        }
        final HelpSearchHit hit = hits[index - 1];
        return ListTile(
          dense: true,
          title: Text(
            hit.section.title.isEmpty
                ? hit.chapter.title
                : '${hit.chapter.title} — ${hit.section.title}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          subtitle: Text(
            hit.snippet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _selectChapter(
            hit.chapter.fileName,
            anchor: hit.section.anchor,
          ),
        );
      },
    );
  }

  Widget _buildChapter(
    HelpLibrary library,
    LearnAnywhereLocalizations messages, {
    bool showBack = false,
  }) {
    final HelpChapter chapter =
        library.chapterByFileName(_selectedFileName ?? '') ??
        library.chapters.first;
    final ThemeData theme = Theme.of(context);
    final MarkdownStyleSheet styleSheet = _styleSheet(theme);

    _sectionKeys.clear();
    final List<Widget> blocks = <Widget>[];
    for (final HelpSection section in chapter.sections) {
      final GlobalKey key = GlobalKey();
      if (section.anchor.isNotEmpty) {
        _sectionKeys[section.anchor] = key;
      }
      blocks.add(
        Padding(
          key: key,
          padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapMedium),
          child: MarkdownBody(
            data: section.markdown,
            styleSheet: styleSheet,
            onTapLink: (String text, String? href, String title) =>
                _onTapLink(href),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: Text(
                messages.message(LearnAnywhereMessage.helpContents),
              ),
              onPressed: () =>
                  setState(() => _showChapterOnNarrow = false),
            ),
          ),
        if (chapter.isFallback)
          _FallbackNotice(
            label: messages.message(LearnAnywhereMessage.helpEnglishFallback),
          ),
        Expanded(
          child: Scrollbar(
            controller: _chapterScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _chapterScrollController,
              padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
              child: SelectionArea(
                child: ConstrainedBox(
                  // Long help prose is unreadable at full desktop width.
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: blocks,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _styleSheet(ThemeData theme) {
    final ColorScheme colorScheme = theme.colorScheme;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      // fromTheme asks for a bare 'monospace' family, which resolves to
      // whatever the host has — and to a proportional face when nothing
      // matches. Pin the bundled family instead, as everywhere else.
      code: LearnAnywhereTokens.monospace(
        theme.textTheme.bodyMedium,
      ).copyWith(backgroundColor: colorScheme.surfaceContainerHighest),
      codeblockDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      tableBorder: TableBorder.all(color: colorScheme.outlineVariant),
      a: TextStyle(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: colorScheme.primary,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
    );
  }
}

final class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(
        horizontal: LearnAnywhereTokens.gapLarge,
        vertical: LearnAnywhereTokens.gapSmall,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.translate, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: LearnAnywhereTokens.gapSmall),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
