import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';

/// Asset sub-path, below a language folder, that holds the bundled user guide.
///
/// The chapters live in ui_kit rather than in a shell because a Flutter asset
/// can only be declared by the package that owns the file, and both the desktop
/// and the mobile shell show the same guide. See `assets:` in ui_kit's
/// `pubspec.yaml`.
const String kHelpAssetRoot = 'assets/help';

/// Language the guide is always written in, and the fallback for any chapter
/// that has not been translated yet.
const String kHelpFallbackLanguage = 'en';

/// One `##` section of a help chapter.
///
/// Sections are the granularity of both search hits and in-page anchors, so a
/// chapter is rendered as a column of sections rather than as one blob.
final class HelpSection {
  /// Creates a section.
  const HelpSection({
    required this.anchor,
    required this.title,
    required this.markdown,
  });

  /// GitHub-style slug of [title], used as the `#anchor` link target.
  ///
  /// Empty for the lead section — the text between the chapter's `#` heading
  /// and its first `##` heading.
  final String anchor;

  /// Heading text without the leading `##`. Empty for the lead section.
  final String title;

  /// The section's Markdown, including its own heading line.
  final String markdown;
}

/// One chapter file of the user guide.
final class HelpChapter {
  /// Creates a chapter.
  const HelpChapter({
    required this.fileName,
    required this.title,
    required this.sections,
    required this.isFallback,
  });

  /// Base file name, e.g. `02-concepts.md`. Also the link target other
  /// chapters use, and the sort key: chapters are ordered by their numeric
  /// filename prefix.
  final String fileName;

  /// The chapter's `#` heading, used as its entry in the contents list.
  final String title;

  /// The chapter's sections in document order. The first one is the lead
  /// section and may have an empty [HelpSection.title].
  final List<HelpSection> sections;

  /// Whether this chapter was read from the fallback language because the
  /// requested language has no file for it. The viewer shows a notice.
  final bool isFallback;

  /// The chapter's full Markdown source.
  String get markdown =>
      sections.map((HelpSection section) => section.markdown).join('\n\n');
}

/// A search match, always attributed to the section it was found in so the
/// viewer can scroll straight to the relevant heading.
final class HelpSearchHit {
  /// Creates a search hit.
  const HelpSearchHit({
    required this.chapter,
    required this.section,
    required this.snippet,
  });

  /// Chapter the match was found in.
  final HelpChapter chapter;

  /// Section the match was found in.
  final HelpSection section;

  /// The matching source line, trimmed and shortened for display.
  final String snippet;
}

/// The bundled user guide for one language, parsed and searchable.
final class HelpLibrary {
  const HelpLibrary._(this.chapters);

  /// Chapters in contents order.
  final List<HelpChapter> chapters;

  /// Whether the guide is empty, i.e. no chapter asset could be read.
  bool get isEmpty => chapters.isEmpty;

  /// Reads and parses the guide for [languageCode] from [bundle].
  ///
  /// Chapters are discovered from the asset manifest, never from a list in
  /// Dart, so adding a chapter is a matter of dropping the file into both
  /// language folders. A chapter missing for [languageCode] falls back to
  /// [kHelpFallbackLanguage] and is flagged via [HelpChapter.isFallback].
  static Future<HelpLibrary> load(
    AssetBundle bundle, {
    required String languageCode,
  }) async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      bundle,
    );
    final List<String> keys = manifest.listAssets();

    final Map<String, String> localized = _chapterKeys(keys, languageCode);
    final Map<String, String> fallback = _chapterKeys(
      keys,
      kHelpFallbackLanguage,
    );

    final List<String> fileNames =
        <String>{...localized.keys, ...fallback.keys}.toList()..sort();

    final List<HelpChapter> chapters = <HelpChapter>[];
    for (final String fileName in fileNames) {
      final bool isFallback = !localized.containsKey(fileName);
      final String? key = localized[fileName] ?? fallback[fileName];
      if (key == null) {
        continue;
      }
      final String source = await bundle.loadString(key);
      chapters.add(
        parseChapter(fileName, source, isFallback: isFallback),
      );
    }
    return HelpLibrary._(List<HelpChapter>.unmodifiable(chapters));
  }

  /// Builds a library from already-loaded sources, keyed by base file name.
  ///
  /// Exists so parsing and search can be tested without an asset bundle.
  /// [fallbackFileNames] names the entries that came from the fallback
  /// language.
  static HelpLibrary fromSources(
    Map<String, String> sources, {
    Set<String> fallbackFileNames = const <String>{},
  }) {
    final List<String> fileNames = sources.keys.toList()..sort();
    return HelpLibrary._(
      List<HelpChapter>.unmodifiable(
        fileNames.map(
          (String fileName) => parseChapter(
            fileName,
            sources[fileName]!,
            isFallback: fallbackFileNames.contains(fileName),
          ),
        ),
      ),
    );
  }

  /// Returns the chapter named [fileName], or `null` if the guide has none.
  HelpChapter? chapterByFileName(String fileName) {
    for (final HelpChapter chapter in chapters) {
      if (chapter.fileName == fileName) {
        return chapter;
      }
    }
    return null;
  }

  /// Returns every line of the guide matching [query], case- and
  /// accent-insensitively, in contents order.
  ///
  /// Matching is line-based rather than offset-based on purpose: accent
  /// folding is not always length-preserving (German `ß` folds to `ss`), so an
  /// index into the folded text cannot be mapped back onto the original.
  /// Reporting the whole original line sidesteps that entirely.
  List<HelpSearchHit> search(String query) {
    final String needle = _fold(query);
    if (needle.isEmpty) {
      return const <HelpSearchHit>[];
    }
    final List<HelpSearchHit> hits = <HelpSearchHit>[];
    for (final HelpChapter chapter in chapters) {
      for (final HelpSection section in chapter.sections) {
        for (final String line in section.markdown.split('\n')) {
          final String text = line.trim();
          if (text.isEmpty || !_fold(text).contains(needle)) {
            continue;
          }
          hits.add(
            HelpSearchHit(
              chapter: chapter,
              section: section,
              snippet: _snippet(text),
            ),
          );
        }
      }
    }
    return List<HelpSearchHit>.unmodifiable(hits);
  }

  /// Parses one chapter's Markdown [source].
  ///
  /// The `#` heading becomes the title and `##` headings start new sections.
  /// Headings inside fenced code blocks are ignored, so a chapter can show
  /// Markdown examples without splitting itself apart.
  static HelpChapter parseChapter(
    String fileName,
    String source, {
    bool isFallback = false,
  }) {
    final List<String> lines = source.split('\n');
    final List<HelpSection> sections = <HelpSection>[];
    final StringBuffer buffer = StringBuffer();
    String title = '';
    String sectionTitle = '';
    bool inFence = false;

    void flush() {
      final String markdown = buffer.toString().trimRight();
      buffer.clear();
      if (markdown.isEmpty) {
        return;
      }
      sections.add(
        HelpSection(
          anchor: sectionTitle.isEmpty ? '' : headingAnchor(sectionTitle),
          title: sectionTitle,
          markdown: markdown,
        ),
      );
    }

    for (final String line in lines) {
      if (line.trimLeft().startsWith('```')) {
        inFence = !inFence;
      } else if (!inFence) {
        if (title.isEmpty && line.startsWith('# ')) {
          title = line.substring(2).trim();
        } else if (line.startsWith('## ')) {
          flush();
          sectionTitle = line.substring(3).trim();
        }
      }
      buffer.writeln(line);
    }
    flush();

    return HelpChapter(
      fileName: fileName,
      title: title.isEmpty ? fileName : title,
      sections: List<HelpSection>.unmodifiable(sections),
      isFallback: isFallback,
    );
  }

  /// Converts a heading to the GitHub-style slug used as its `#anchor`.
  static String headingAnchor(String heading) {
    final StringBuffer slug = StringBuffer();
    for (final int rune in heading.toLowerCase().runes) {
      final String ch = String.fromCharCode(rune);
      if (ch == ' ' || ch == '-' || ch == '_') {
        slug.write('-');
      } else if (_slugCharacter.hasMatch(ch)) {
        slug.write(ch);
      }
    }
    return slug.toString();
  }

  static final RegExp _slugCharacter = RegExp('[a-z0-9]');

  /// Maps base file name to asset key for every chapter of [languageCode].
  ///
  /// Asset keys are URI-style and always `/`-separated — they are not
  /// filesystem paths, so splitting them on `/` is correct here and is not the
  /// hand-rolled path handling the repo rules forbid.
  ///
  /// Both the bare key (`assets/help/en/x.md`, how ui_kit's own tests see its
  /// assets) and the package-prefixed key
  /// (`packages/learn_anywhere_ui_kit/assets/help/en/x.md`, how a shell sees
  /// them) are accepted.
  static Map<String, String> _chapterKeys(
    List<String> keys,
    String languageCode,
  ) {
    final String marker = '$kHelpAssetRoot/$languageCode/';
    final Map<String, String> found = <String, String>{};
    for (final String key in keys) {
      if (!key.endsWith('.md') || !key.contains(marker)) {
        continue;
      }
      found[key.substring(key.lastIndexOf('/') + 1)] = key;
    }
    return found;
  }

  static String _fold(String value) =>
      normalizeText(value, const TextMatchOptions());

  static String _snippet(String line) {
    const int maxLength = 160;
    if (line.length <= maxLength) {
      return line;
    }
    return '${line.substring(0, maxLength).trimRight()}...';
  }
}
