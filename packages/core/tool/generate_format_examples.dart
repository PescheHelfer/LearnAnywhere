/// Regenerates the canonical `.inf`/`.vok` format examples in
/// `docs/format-examples/`.
///
/// These files are the format CONTRACT handed to the Converter agent. They are
/// produced by the real serializers so they can never drift from the code; the
/// round-trip test in `core_test.dart` re-encodes them and asserts equality.
///
/// Run from the package root:
///   dart run tool/generate_format_examples.dart
library;

import 'dart:io';

import 'package:learn_anywhere_core/core.dart';

void main() {
  // A mask with TWO categories, to demonstrate that field ids form a single
  // 0-based space spanning the whole mask (0..5 below), not a per-category one.
  // maskId uses the app prefix; a Converter-produced file would instead carry
  // an "m_legacy_"+hash id, which this app reads verbatim and never recomputes.
  const LearningMask mask = LearningMask(
    maskId: 'm_new_example-french-0001',
    revision: 3,
    name: 'French vocabulary',
    direction1Label: 'DE → FR',
    direction2Label: 'FR → DE',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 0,
        name: 'Noun',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: 'German',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: 'French',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            // A hidden field (empty display name) still has a stable id and can
            // hold a value; it is simply not shown in the apps.
            id: 2,
            name: '',
            length: 20,
            equalGroup: 0,
            role1: FieldRole.remark,
            role2: FieldRole.remark,
          ),
        ],
      ),
      CategoryDefinition(
        id: 1,
        name: 'Verb',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 3,
            name: 'German',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            // Two interchangeable answers (equalGroup 1): order-independent.
            id: 4,
            name: 'French A',
            length: 40,
            equalGroup: 1,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            id: 5,
            name: 'French B',
            length: 40,
            equalGroup: 1,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
        ],
      ),
    ],
  );

  // Units key their values by FieldDefinition.id (serialized as JSON string
  // keys). Note the rich-text value and that unreferenced fields may be omitted.
  final LearningDeck deck = LearningDeck(
    mask: mask,
    units: <LearningUnit>[
      const LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('das Haus'),
          1: FieldValue.plain('la maison'),
          2: FieldValue.plain(''),
        },
      ),
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: const FieldValue.plain('der Mond'),
          1: FieldValue.rich(<RichTextRun>[
            const RichTextRun(text: 'la lune', bold: true, color: '#3366CC'),
          ]),
        },
      ),
      const LearningUnit(
        categoryId: 1,
        fields: <int, FieldValue>{
          3: FieldValue.plain('gehen'),
          4: FieldValue.plain('aller'),
          5: FieldValue.plain('marcher'),
        },
      ),
    ],
  );

  final Directory outDir = Directory('../../docs/format-examples');
  outDir.createSync(recursive: true);
  File('${outDir.path}/example.inf').writeAsStringSync(encodeMaskJson(mask));
  File('${outDir.path}/example.vok').writeAsStringSync(encodeDeckJson(deck));
  stdout.writeln('Wrote example.inf and example.vok to ${outDir.path}');
}
