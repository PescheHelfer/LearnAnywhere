import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Language folders under `assets/help/`. Every one of them must hold exactly
/// the same chapter file names.
const List<String> _languages = <String>['en', 'de'];

/// Matches a Markdown inline link, capturing its target.
final RegExp _link = RegExp(r'\[[^\]]*\]\(([^)]+)\)');

/// Reads the chapter files of one language straight off disk.
///
/// Package-root-relative like `packages/core/test/core_test.dart` reads its
/// fixtures, so the test works under `melos` and under a bare `flutter test`
/// alike. Forward slashes are correct on every host here — Dart's `File`
/// accepts them on Windows too.
Map<String, String> _chapters(String language) {
  final Directory dir = Directory('assets/help/$language');
  final Map<String, String> chapters = <String, String>{};
  for (final FileSystemEntity entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.md')) {
      final String name = entity.uri.pathSegments.last;
      chapters[name] = entity.readAsStringSync();
    }
  }
  return chapters;
}

/// Anchors a link may target: the slug of every `##` heading.
///
/// Deliberately excludes `#` and `###` headings. Only `##` starts a
/// [HelpSection], and only a section is a scroll target in [HelpViewer], so an
/// anchor of any other level would resolve on GitHub but silently do nothing
/// in the app.
Set<String> _anchors(String source) {
  final Set<String> anchors = <String>{};
  bool inFence = false;
  for (final String line in source.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
    } else if (!inFence && line.startsWith('## ')) {
      anchors.add(HelpLibrary.headingAnchor(line.substring(3).trim()));
    }
  }
  return anchors;
}

void main() {
  group('bundled user guide', () {
    test('every language folder holds the same chapters', () {
      final Set<String> english = _chapters('en').keys.toSet();
      expect(english, isNotEmpty);
      for (final String language in _languages) {
        expect(
          _chapters(language).keys.toSet(),
          english,
          reason:
              'assets/help/$language must hold exactly the same chapter files '
              'as assets/help/en — the viewer pairs them by file name.',
        );
      }
    });

    test('every chapter has exactly one non-empty top-level heading', () {
      for (final String language in _languages) {
        _chapters(language).forEach((String name, String source) {
          final List<String> headings = source
              .split('\n')
              .where((String line) => line.startsWith('# '))
              .toList();
          expect(
            headings.length,
            1,
            reason: '$language/$name must have exactly one "# " heading; it '
                'becomes the chapter title in the contents list.',
          );
          expect(headings.single.substring(2).trim(), isNotEmpty);
        });
      }
    });

    test('every chapter link resolves to a chapter and an anchor', () {
      for (final String language in _languages) {
        final Map<String, String> chapters = _chapters(language);
        chapters.forEach((String name, String source) {
          for (final RegExpMatch match in _link.allMatches(source)) {
            final String href = match.group(1)!;
            if (href.startsWith('http') || href.startsWith('mailto:')) {
              continue;
            }
            final int hash = href.indexOf('#');
            final String file = hash < 0 ? href : href.substring(0, hash);
            final String anchor = hash < 0 ? '' : href.substring(hash + 1);
            final String target = file.isEmpty ? name : file;

            expect(
              chapters.containsKey(target),
              isTrue,
              reason: '$language/$name links to "$href", but '
                  'assets/help/$language/$target does not exist.',
            );
            if (anchor.isNotEmpty) {
              expect(
                _anchors(chapters[target]!),
                contains(anchor),
                reason: '$language/$name links to "$href", but $target has no '
                    '"## " heading with that anchor.',
              );
            }
          }
        });
      }
    });

    test('chapters parse into the order and titles the contents list shows', () {
      final HelpLibrary library = HelpLibrary.fromSources(_chapters('en'));
      final List<String> fileNames = library.chapters
          .map((HelpChapter chapter) => chapter.fileName)
          .toList();

      expect(fileNames.first, '00-index.md');
      expect(
        fileNames,
        equals(<String>[...fileNames]..sort()),
        reason: 'chapters are ordered by their numeric filename prefix',
      );
      expect(
        library.chapterByFileName('01-getting-started.md')!.title,
        'Getting started',
      );
      expect(library.chapterByFileName('does-not-exist.md'), isNull);
    });
  });

  group('chapter parsing', () {
    test('splits at "## " and keeps the lead section', () {
      final HelpChapter chapter = HelpLibrary.parseChapter(
        '01-x.md',
        '# Title\n\nLead text.\n\n## First\n\nOne.\n\n## Second\n\nTwo.\n',
      );

      expect(chapter.title, 'Title');
      expect(chapter.sections.length, 3);
      expect(chapter.sections.first.title, isEmpty);
      expect(chapter.sections.first.anchor, isEmpty);
      expect(chapter.sections.first.markdown, contains('Lead text.'));
      expect(chapter.sections[1].title, 'First');
      expect(chapter.sections[1].anchor, 'first');
      expect(chapter.sections[1].markdown, startsWith('## First'));
      expect(chapter.sections.last.title, 'Second');
    });

    test('ignores headings inside fenced code blocks', () {
      final HelpChapter chapter = HelpLibrary.parseChapter(
        '01-x.md',
        '# Title\n\n```\n# not a title\n## not a section\n```\n\n## Real\n\nx\n',
      );

      expect(chapter.title, 'Title');
      expect(chapter.sections.length, 2);
      expect(chapter.sections.last.title, 'Real');
    });

    test('falls back to the file name when a chapter has no heading', () {
      final HelpChapter chapter = HelpLibrary.parseChapter('99-x.md', 'body\n');
      expect(chapter.title, '99-x.md');
    });

    test('slugs headings the way Markdown anchors are written', () {
      expect(HelpLibrary.headingAnchor('The three kinds of file'),
          'the-three-kinds-of-file');
      expect(HelpLibrary.headingAnchor('Level learning (3 to 0)'),
          'level-learning-3-to-0');
      expect(HelpLibrary.headingAnchor('Wie Antworten bewertet werden'),
          'wie-antworten-bewertet-werden');
    });
  });

  group('search', () {
    final HelpLibrary library = HelpLibrary.fromSources(<String, String>{
      '00-a.md': '# Alpha\n\n## Erste Stufe\n\nDie Übung beginnt hier.\n',
      '01-b.md': '# Beta\n\n## Second\n\nNothing to see.\n',
    });

    test('ignores case', () {
      final List<HelpSearchHit> hits = library.search('NOTHING');
      expect(hits.length, 1);
      expect(hits.single.chapter.title, 'Beta');
      expect(hits.single.section.title, 'Second');
      expect(hits.single.snippet, 'Nothing to see.');
    });

    test('ignores accents in either direction', () {
      expect(library.search('ubung').length, 1);
      expect(library.search('Übung').length, 1);
    });

    test('attributes a hit to its section so the viewer can scroll to it', () {
      final HelpSearchHit hit = library.search('beginnt').single;
      expect(hit.section.anchor, 'erste-stufe');
    });

    test('returns nothing for an empty or unmatched query', () {
      expect(library.search(''), isEmpty);
      expect(library.search('   '), isEmpty);
      expect(library.search('zzz'), isEmpty);
    });
  });

  group('translation fallback', () {
    test('flags chapters served from the fallback language', () {
      final HelpLibrary library = HelpLibrary.fromSources(
        <String, String>{'00-a.md': '# A\n', '01-b.md': '# B\n'},
        fallbackFileNames: <String>{'01-b.md'},
      );

      expect(library.chapterByFileName('00-a.md')!.isFallback, isFalse);
      expect(library.chapterByFileName('01-b.md')!.isFallback, isTrue);
    });
  });
}
