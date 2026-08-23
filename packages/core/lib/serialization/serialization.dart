/// JSON encoders, decoders, and validators for Learn Anywhere file formats.
library;

import 'dart:convert';

import '../models/models.dart';

/// Mask file format marker.
const String maskFormat = 'learn-anywhere/mask';

/// Learning deck file format marker.
const String lessonFormat = 'learn-anywhere/lessons';

/// Statistics file format marker.
const String statisticsFormat = 'learn-anywhere/statistics';

/// Current supported file format version for `.inf` masks and `.vok` decks.
const int currentFormatVersion = 1;

/// Current supported `.sta` statistics format version.
///
/// Version 2 adds the optional `levelLearning` section. Decoding accepts both
/// version 1 (no Level-Learning data) and version 2.
///
/// The per-unit `hash` ([UnitStats.hash]) is deliberately an ADDITIVE field at
/// version 2 rather than a version 3: unknown keys are ignored in both
/// directions, so a file with hashes still loads in a build that predates them,
/// and a file without hashes still loads here. Bumping the version would only
/// make older builds reject the file for no gain.
const int currentStatisticsVersion = 2;

/// A user-facing validation failure for a loaded file.
final class ValidationException implements Exception {
  /// Creates a validation exception at [path].
  const ValidationException(this.message, {this.path = r'$'});

  /// Human-readable validation failure.
  final String message;

  /// JSON path where validation failed.
  final String path;

  @override
  String toString() => '$path: $message';
}

/// Parses a mask JSON string.
LearningMask decodeMaskJson(String source) {
  return decodeMask(jsonDecode(source));
}

/// Encodes a mask as pretty JSON.
String encodeMaskJson(LearningMask mask) {
  return _prettyJson(encodeMask(mask));
}

/// Parses a learning deck JSON string.
LearningDeck decodeDeckJson(String source) {
  return decodeDeck(jsonDecode(source));
}

/// Encodes a learning deck as pretty JSON.
String encodeDeckJson(LearningDeck deck) {
  return _prettyJson(encodeDeck(deck));
}

/// Parses a statistics sidecar JSON string.
StatisticsFile decodeStatisticsJson(String source) {
  return decodeStatistics(jsonDecode(source));
}

/// Encodes statistics as pretty JSON.
String encodeStatisticsJson(StatisticsFile statistics) {
  return _prettyJson(encodeStatistics(statistics));
}

/// Decodes and validates a mask object.
LearningMask decodeMask(Object? value) {
  final Map<String, Object?> json = _asMap(value, r'$');
  _expectFormat(json, maskFormat, r'$');
  _expectVersion(json, r'$');
  return _decodeMaskBody(json, r'$');
}

/// Encodes a mask object.
Map<String, Object?> encodeMask(LearningMask mask) {
  return <String, Object?>{
    'format': maskFormat,
    'version': currentFormatVersion,
    ..._encodeMaskBody(mask),
  };
}

/// Decodes and validates a learning deck object.
LearningDeck decodeDeck(Object? value) {
  final Map<String, Object?> json = _asMap(value, r'$');
  _expectFormat(json, lessonFormat, r'$');
  _expectVersion(json, r'$');
  final Object? rawMask = json['mask'];
  final LearningMask mask = _decodeEmbeddedMask(rawMask, r'$.mask');
  // Self-healing (Step 3): a mask that carried no maskId is a legacy or
  // hand-edited APP file whose unit values are keyed by field NAME, not id.
  // (A file with a maskId is authoritative new format: keys are field ids.)
  // This flag disambiguates the two, so even a field literally named "3" is
  // not mistaken for id 3.
  final bool legacyFieldKeys = !_hasMaskId(rawMask);
  final List<Object?> unitValues = _asList(json['units'], r'$.units');
  final List<LearningUnit> units = <LearningUnit>[];
  for (var index = 0; index < unitValues.length; index += 1) {
    units.add(
      _decodeUnit(
        unitValues[index],
        mask,
        '\$.units[$index]',
        legacyFieldKeys: legacyFieldKeys,
      ),
    );
  }
  return LearningDeck(
    mask: mask,
    units: List<LearningUnit>.unmodifiable(units),
  );
}

/// Encodes a learning deck object.
Map<String, Object?> encodeDeck(LearningDeck deck) {
  return <String, Object?>{
    'format': lessonFormat,
    'version': currentFormatVersion,
    'mask': _encodeMaskBody(deck.mask),
    'units': deck.units.map(_encodeUnit).toList(growable: false),
  };
}

/// Decodes and validates a statistics sidecar object.
StatisticsFile decodeStatistics(Object? value) {
  final Map<String, Object?> json = _asMap(value, r'$');
  _expectFormat(json, statisticsFormat, r'$');
  _expectStatisticsVersion(json, r'$');
  // Additive at version 2, exactly like the per-unit identity hash: a file
  // with no `scope` key is the working record, which is every `.sta` written
  // before all-time statistics existed, and an unrecognised value means the
  // same rather than failing the load.
  final Object? rawScope = json['scope'];
  final StatisticsScope scope = rawScope is String
      ? StatisticsScope.values
                .where((StatisticsScope value) => value.name == rawScope)
                .firstOrNull ??
            StatisticsScope.session
      : StatisticsScope.session;
  final String deckRef = _asString(json['deckRef'], r'$.deckRef');
  final List<Object?> unitValues = _asList(json['perUnit'], r'$.perUnit');
  final List<UnitStats> perUnit = <UnitStats>[];
  for (var index = 0; index < unitValues.length; index += 1) {
    perUnit.add(_decodeUnitStats(unitValues[index], '\$.perUnit[$index]'));
  }
  // The Level-Learning section is optional: absent in version-1 files and
  // omittable in version-2 files. A missing section decodes to null.
  final Object? rawLevelLearning = json['levelLearning'];
  final LevelLearningStats? levelLearning = rawLevelLearning == null
      ? null
      : _decodeLevelLearning(rawLevelLearning, r'$.levelLearning');
  // Written since the Level-0 write-through landed; absent (or unrecognised,
  // e.g. a mode this build no longer knows) simply decodes to "unknown".
  final Object? rawMode = json['lastSessionMode'];
  final SessionMode? lastSessionMode = rawMode is String
      ? SessionMode.values
            .where((SessionMode mode) => mode.name == rawMode)
            .firstOrNull
      : null;
  return StatisticsFile(
    deckRef: deckRef,
    scope: scope,
    perUnit: List<UnitStats>.unmodifiable(perUnit),
    levelLearning: levelLearning,
    lastSessionMode: lastSessionMode,
  );
}

/// Encodes a statistics sidecar object.
Map<String, Object?> encodeStatistics(StatisticsFile statistics) {
  return <String, Object?>{
    'format': statisticsFormat,
    'version': currentStatisticsVersion,
    // Written only for the lifetime record, so a working `.sta` stays exactly
    // the document every earlier build wrote and reads.
    if (statistics.scope != StatisticsScope.session)
      'scope': statistics.scope.name,
    'deckRef': statistics.deckRef,
    'perUnit': statistics.perUnit.map(_encodeUnitStats).toList(growable: false),
    if (statistics.levelLearning != null)
      'levelLearning': _encodeLevelLearning(statistics.levelLearning!),
    if (statistics.lastSessionMode != null)
      'lastSessionMode': statistics.lastSessionMode!.name,
  };
}

LearningMask _decodeEmbeddedMask(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final Object? format = json['format'];
  if (format != null) {
    _expectFormat(json, maskFormat, path);
    _expectVersion(json, path);
  }
  return _decodeMaskBody(json, path);
}

LearningMask _decodeMaskBody(Map<String, Object?> json, String path) {
  // Self-healing (see Step 3): app files may predate identity fields, so read
  // maskId/revision tolerantly. A missing or blank maskId means this file was
  // authored before identity existed (or hand-edited); mint a fresh app maskId
  // rather than crash. A file's existing maskId is opaque and never recomputed.
  final Object? rawMaskId = json['maskId'];
  final String maskId = rawMaskId is String && rawMaskId.isNotEmpty
      ? rawMaskId
      : mintNewMaskId();
  final Object? rawRevision = json['revision'];
  final int revision = rawRevision is int && rawRevision >= 0 ? rawRevision : 0;
  final String name = _asString(json['name'], '$path.name');
  final String direction1Label = _asString(
    json['direction1Label'],
    '$path.direction1Label',
  );
  final String direction2Label = _asString(
    json['direction2Label'],
    '$path.direction2Label',
  );
  final List<Object?> categoryValues = _asList(
    json['categories'],
    '$path.categories',
  );
  if (categoryValues.length > maxCategoriesPerMask) {
    throw ValidationException(
      'A mask may contain at most $maxCategoriesPerMask categories.',
      path: '$path.categories',
    );
  }
  final List<CategoryDefinition> categories = <CategoryDefinition>[];
  final Set<int> categoryIds = <int>{};
  // Field ids are unique across the WHOLE mask (a single 0-based space), so
  // fallback numbering for id-less legacy fields continues across categories in
  // array order. [fieldIdBase] is the global ordinal of a category's first
  // field.
  final Set<int> fieldIds = <int>{};
  var fieldIdBase = 0;
  for (var index = 0; index < categoryValues.length; index += 1) {
    final CategoryDefinition category = _decodeCategory(
      categoryValues[index],
      '$path.categories[$index]',
      fieldIdBase,
      index,
    );
    if (!categoryIds.add(category.id)) {
      throw ValidationException(
        'Duplicate category id ${category.id}.',
        path: '$path.categories[$index].id',
      );
    }
    for (var fieldIndex = 0; fieldIndex < category.fields.length; fieldIndex++) {
      if (!fieldIds.add(category.fields[fieldIndex].id)) {
        throw ValidationException(
          'Duplicate field id ${category.fields[fieldIndex].id} in mask.',
          path: '$path.categories[$index].fields[$fieldIndex].id',
        );
      }
    }
    fieldIdBase += category.fields.length;
    categories.add(category);
  }
  return LearningMask(
    maskId: maskId,
    revision: revision,
    name: name,
    direction1Label: direction1Label,
    direction2Label: direction2Label,
    categories: List<CategoryDefinition>.unmodifiable(categories),
  );
}

Map<String, Object?> _encodeMaskBody(LearningMask mask) {
  return <String, Object?>{
    'maskId': mask.maskId,
    'revision': mask.revision,
    'name': mask.name,
    'direction1Label': mask.direction1Label,
    'direction2Label': mask.direction2Label,
    'categories': mask.categories.map(_encodeCategory).toList(growable: false),
  };
}

CategoryDefinition _decodeCategory(
  Object? value,
  String path,
  int fieldIdBase,
  int fallbackCategoryId,
) {
  final Map<String, Object?> json = _asMap(value, path);
  // Self-healing (Step 3): category ids are 0-based. Read tolerantly — a
  // missing or invalid id falls back to the category's array position, which
  // reproduces this app's assignment scheme for older/hand-edited files.
  final Object? rawId = json['id'];
  final int id = rawId is int && rawId >= 0 ? rawId : fallbackCategoryId;
  final String name = _asString(json['name'], '$path.name');
  if (name.length > maxCategoryNameLength) {
    throw ValidationException(
      'Category name may contain at most $maxCategoryNameLength characters.',
      path: '$path.name',
    );
  }
  final List<Object?> fieldValues = _asList(json['fields'], '$path.fields');
  if (fieldValues.length > maxFieldsPerCategory) {
    throw ValidationException(
      'A category may contain at most $maxFieldsPerCategory fields.',
      path: '$path.fields',
    );
  }
  final List<FieldDefinition> fields = <FieldDefinition>[];
  for (var index = 0; index < fieldValues.length; index += 1) {
    fields.add(
      _decodeField(
        fieldValues[index],
        '$path.fields[$index]',
        fieldIdBase + index,
      ),
    );
  }
  return CategoryDefinition(
    id: id,
    name: name,
    fields: List<FieldDefinition>.unmodifiable(fields),
  );
}

Map<String, Object?> _encodeCategory(CategoryDefinition category) {
  return <String, Object?>{
    'id': category.id,
    'name': category.name,
    'fields': category.fields.map(_encodeField).toList(growable: false),
  };
}

FieldDefinition _decodeField(Object? value, String path, int fallbackId) {
  final Map<String, Object?> json = _asMap(value, path);
  // Self-healing (see Step 3): read the field id tolerantly. A missing id means
  // an older/hand-edited app file; fall back to the field's mask-wide array
  // ordinal, which reproduces this app's 0-based assignment scheme.
  final Object? rawId = json['id'];
  final int id = rawId is int && rawId >= 0 ? rawId : fallbackId;
  final String name = _asString(json['name'], '$path.name');
  final int length = _asInt(json['length'], '$path.length');
  if (length < minFieldLength || length > maxFieldLength) {
    throw ValidationException(
      'Field length must be between $minFieldLength and $maxFieldLength.',
      path: '$path.length',
    );
  }
  final int equalGroup = _asInt(json['equalGroup'], '$path.equalGroup');
  if (equalGroup < 0) {
    throw ValidationException(
      'Equal-group must be zero or greater.',
      path: '$path.equalGroup',
    );
  }
  return FieldDefinition(
    id: id,
    name: name,
    length: length,
    equalGroup: equalGroup,
    role1: _decodeRole(json['role1'], '$path.role1'),
    role2: _decodeRole(json['role2'], '$path.role2'),
  );
}

Map<String, Object?> _encodeField(FieldDefinition field) {
  return <String, Object?>{
    'id': field.id,
    'name': field.name,
    'length': field.length,
    'equalGroup': field.equalGroup,
    'role1': field.role1.code,
    'role2': field.role2.code,
  };
}

LearningUnit _decodeUnit(
  Object? value,
  LearningMask mask,
  String path, {
  required bool legacyFieldKeys,
}) {
  final Map<String, Object?> json = _asMap(value, path);
  final int categoryId = _asInt(json['categoryId'], '$path.categoryId');
  final CategoryDefinition? category = mask.categoryById(categoryId);
  if (category == null) {
    throw ValidationException(
      'Unknown category id $categoryId.',
      path: '$path.categoryId',
    );
  }
  final Map<String, Object?> fieldJson = _asMap(json['fields'], '$path.fields');
  // Unit field VALUES are keyed by FieldDefinition.id, serialized as JSON
  // string keys (JSON object keys must be strings). The field's display name is
  // not stored here — it lives in the mask.
  final Map<int, FieldValue> fields = <int, FieldValue>{};
  for (final MapEntry<String, Object?> entry in fieldJson.entries) {
    final int fieldId = legacyFieldKeys
        // Legacy files keyed values by field NAME. Resolve to the (self-healed)
        // field id via the mask. A name matching no field references a field
        // no longer present, so its value is dropped tolerantly.
        ? category.fieldNamed(entry.key)?.id ?? -1
        : int.tryParse(entry.key) ?? -1;
    if (legacyFieldKeys && fieldId < 0) {
      continue;
    }
    if (fieldId < 0) {
      throw ValidationException(
        'Unit field keys must be non-negative integer field ids.',
        path: '$path.fields.${entry.key}',
      );
    }
    final FieldValue fieldValue = _decodeFieldValue(
      entry.value,
      '$path.fields.${entry.key}',
    );
    final FieldDefinition? definition = category.fieldById(fieldId);
    if (definition != null && fieldValue.plainText.length > definition.length) {
      throw ValidationException(
        'Field value exceeds declared length ${definition.length}.',
        path: '$path.fields.${entry.key}',
      );
    }
    fields[fieldId] = fieldValue;
  }
  return LearningUnit(
    categoryId: categoryId,
    fields: Map<int, FieldValue>.unmodifiable(fields),
  );
}

bool _hasMaskId(Object? maskValue) {
  if (maskValue is! Map) {
    return false;
  }
  final Object? maskId = maskValue['maskId'];
  return maskId is String && maskId.isNotEmpty;
}

Map<String, Object?> _encodeUnit(LearningUnit unit) {
  return <String, Object?>{
    'categoryId': unit.categoryId,
    'fields': <String, Object?>{
      for (final MapEntry<int, FieldValue> entry in unit.fields.entries)
        entry.key.toString(): _encodeFieldValue(entry.value),
    },
  };
}

FieldValue _decodeFieldValue(Object? value, String path) {
  if (value is String) {
    return FieldValue.plain(value);
  }
  if (value is List<Object?>) {
    final List<RichTextRun> runs = <RichTextRun>[];
    for (var index = 0; index < value.length; index += 1) {
      runs.add(_decodeRichTextRun(value[index], '$path[$index]'));
    }
    return FieldValue.rich(List<RichTextRun>.unmodifiable(runs));
  }
  throw ValidationException(
    'Expected a string or a list of rich text runs.',
    path: path,
  );
}

Object _encodeFieldValue(FieldValue value) {
  return switch (value) {
    PlainFieldValue(:final String text) => text,
    RichFieldValue(:final List<RichTextRun> runs) =>
      runs.map(_encodeRichTextRun).toList(growable: false),
  };
}

RichTextRun _decodeRichTextRun(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final String? color = _nullableString(json['color'], '$path.color');
  final String? highlight = _nullableString(
    json['highlight'],
    '$path.highlight',
  );
  _validateColor(color, '$path.color');
  _validateColor(highlight, '$path.highlight');
  return RichTextRun(
    text: _asString(json['text'], '$path.text'),
    bold: _optionalBool(json['bold'], '$path.bold'),
    italic: _optionalBool(json['italic'], '$path.italic'),
    underline: _optionalBool(json['underline'], '$path.underline'),
    strikethrough: _optionalBool(json['strikethrough'], '$path.strikethrough'),
    color: color,
    highlight: highlight,
  );
}

Map<String, Object?> _encodeRichTextRun(RichTextRun run) {
  final Map<String, Object?> json = <String, Object?>{'text': run.text};
  if (run.bold) {
    json['bold'] = true;
  }
  if (run.italic) {
    json['italic'] = true;
  }
  if (run.underline) {
    json['underline'] = true;
  }
  if (run.strikethrough) {
    json['strikethrough'] = true;
  }
  if (run.color != null) {
    json['color'] = run.color;
  }
  if (run.highlight != null) {
    json['highlight'] = run.highlight;
  }
  return json;
}

UnitStats _decodeUnitStats(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final int index = _asInt(json['index'], '$path.index');
  if (index <= 0) {
    throw ValidationException(
      'Unit index must be positive.',
      path: '$path.index',
    );
  }
  // Optional and additive: files written before per-unit hashes existed simply
  // have no `hash` key, and decode to a null hash ("identity unknown").
  final Object? rawHash = json['hash'];
  return UnitStats(
    index: index,
    direction1: _decodeDirectionStats(json['dir1'], '$path.dir1'),
    direction2: _decodeDirectionStats(json['dir2'], '$path.dir2'),
    hash: rawHash is String && rawHash.isNotEmpty ? rawHash : null,
  );
}

Map<String, Object?> _encodeUnitStats(UnitStats stats) {
  return <String, Object?>{
    'index': stats.index,
    if (stats.hash != null) 'hash': stats.hash,
    'dir1': _encodeDirectionStats(stats.direction1),
    'dir2': _encodeDirectionStats(stats.direction2),
  };
}

DirectionStats _decodeDirectionStats(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final int attempts = _asInt(json['attempts'], '$path.attempts');
  final int correct = _asInt(json['correct'], '$path.correct');
  if (attempts < 0) {
    throw ValidationException(
      'Attempts must be zero or greater.',
      path: '$path.attempts',
    );
  }
  if (correct < 0 || correct > attempts) {
    throw ValidationException(
      'Correct count must be between zero and attempts.',
      path: '$path.correct',
    );
  }
  return DirectionStats(attempts: attempts, correct: correct);
}

Map<String, Object?> _encodeDirectionStats(DirectionStats stats) {
  return <String, Object?>{
    'attempts': stats.attempts,
    'correct': stats.correct,
  };
}

LevelLearningStats _decodeLevelLearning(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final List<Object?> unitValues = _asList(json['perUnit'], '$path.perUnit');
  final List<LevelUnitStats> perUnit = <LevelUnitStats>[];
  for (var index = 0; index < unitValues.length; index += 1) {
    perUnit.add(
      _decodeLevelUnitStats(unitValues[index], '$path.perUnit[$index]'),
    );
  }
  return LevelLearningStats(
    perUnit: List<LevelUnitStats>.unmodifiable(perUnit),
  );
}

Map<String, Object?> _encodeLevelLearning(LevelLearningStats stats) {
  return <String, Object?>{
    'perUnit': stats.perUnit
        .map(_encodeLevelUnitStats)
        .toList(growable: false),
  };
}

LevelUnitStats _decodeLevelUnitStats(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final int index = _asInt(json['index'], '$path.index');
  if (index <= 0) {
    throw ValidationException(
      'Unit index must be positive.',
      path: '$path.index',
    );
  }
  return LevelUnitStats(
    index: index,
    dir1: _decodeLevelDirectionStats(json['dir1'], '$path.dir1'),
    dir2: _decodeLevelDirectionStats(json['dir2'], '$path.dir2'),
  );
}

Map<String, Object?> _encodeLevelUnitStats(LevelUnitStats stats) {
  return <String, Object?>{
    'index': stats.index,
    'dir1': _encodeLevelDirectionStats(stats.dir1),
    'dir2': _encodeLevelDirectionStats(stats.dir2),
  };
}

LevelDirectionStats _decodeLevelDirectionStats(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final int currentLevel = _asInt(json['currentLevel'], '$path.currentLevel');
  if (currentLevel < kFreeRecallLevel || currentLevel > kMaxSupportLevel) {
    throw ValidationException(
      'currentLevel must be between $kFreeRecallLevel and $kMaxSupportLevel.',
      path: '$path.currentLevel',
    );
  }
  final Map<String, Object?> levelsJson = _asMap(json['levels'], '$path.levels');
  // The four level keys 3,2,1,0 are all required; unknown extra keys are
  // tolerated (ignored) so future additions do not break older readers.
  final Map<int, DirectionStats> levels = <int, DirectionStats>{};
  for (var level = kMaxSupportLevel; level >= kFreeRecallLevel; level -= 1) {
    final String key = level.toString();
    if (!levelsJson.containsKey(key)) {
      throw ValidationException(
        'Level key "$key" is required.',
        path: '$path.levels',
      );
    }
    levels[level] = _decodeDirectionStats(
      levelsJson[key],
      '$path.levels.$key',
    );
  }
  return LevelDirectionStats(currentLevel: currentLevel, levels: levels);
}

Map<String, Object?> _encodeLevelDirectionStats(LevelDirectionStats stats) {
  return <String, Object?>{
    'currentLevel': stats.currentLevel,
    'levels': <String, Object?>{
      for (var level = kMaxSupportLevel; level >= kFreeRecallLevel; level -= 1)
        level.toString(): _encodeDirectionStats(
          stats.levels[level] ?? const DirectionStats(),
        ),
    },
  };
}

FieldRole _decodeRole(Object? value, String path) {
  final String code = _asString(value, path);
  try {
    return FieldRole.parse(code);
  } on ArgumentError {
    throw ValidationException('Role must be one of Q, A, or R.', path: path);
  }
}

void _expectFormat(Map<String, Object?> json, String expected, String path) {
  final String format = _asString(json['format'], '$path.format');
  if (format != expected) {
    throw ValidationException(
      'Expected format "$expected".',
      path: '$path.format',
    );
  }
}

void _expectVersion(Map<String, Object?> json, String path) {
  final int version = _asInt(json['version'], '$path.version');
  if (version != currentFormatVersion) {
    throw ValidationException(
      'Unsupported version $version.',
      path: '$path.version',
    );
  }
}

/// Accepts any `.sta` version from 1 up to [currentStatisticsVersion].
void _expectStatisticsVersion(Map<String, Object?> json, String path) {
  final int version = _asInt(json['version'], '$path.version');
  if (version < 1 || version > currentStatisticsVersion) {
    throw ValidationException(
      'Unsupported version $version.',
      path: '$path.version',
    );
  }
}

Map<String, Object?> _asMap(Object? value, String path) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((Object? key, Object? value) {
      if (key is! String) {
        throw ValidationException('Expected string keys.', path: path);
      }
      return MapEntry<String, Object?>(key, value);
    });
  }
  throw ValidationException('Expected an object.', path: path);
}

List<Object?> _asList(Object? value, String path) {
  if (value is List<Object?>) {
    return value;
  }
  if (value is List) {
    return value.cast<Object?>();
  }
  throw ValidationException('Expected a list.', path: path);
}

String _asString(Object? value, String path) {
  if (value is String) {
    return value;
  }
  throw ValidationException('Expected a string.', path: path);
}

String? _nullableString(Object? value, String path) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw ValidationException('Expected a string or null.', path: path);
}

int _asInt(Object? value, String path) {
  if (value is int) {
    return value;
  }
  throw ValidationException('Expected an integer.', path: path);
}

bool _optionalBool(Object? value, String path) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  throw ValidationException('Expected a boolean.', path: path);
}

void _validateColor(String? value, String path) {
  if (value == null) {
    return;
  }
  final RegExp hexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');
  if (!hexColor.hasMatch(value)) {
    throw ValidationException('Expected a #RRGGBB color.', path: path);
  }
}

String _prettyJson(Object? value) {
  return '${const JsonEncoder.withIndent('  ').convert(value)}\n';
}
