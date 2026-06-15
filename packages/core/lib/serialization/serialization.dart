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

/// Current supported file format version.
const int currentFormatVersion = 1;

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
    'name': mask.name,
    'direction1Label': mask.direction1Label,
    'direction2Label': mask.direction2Label,
    'categories': mask.categories.map(_encodeCategory).toList(growable: false),
  };
}

/// Decodes and validates a learning deck object.
LearningDeck decodeDeck(Object? value) {
  final Map<String, Object?> json = _asMap(value, r'$');
  _expectFormat(json, lessonFormat, r'$');
  _expectVersion(json, r'$');
  final LearningMask mask = _decodeEmbeddedMask(json['mask'], r'$.mask');
  final List<Object?> unitValues = _asList(json['units'], r'$.units');
  final List<LearningUnit> units = <LearningUnit>[];
  for (var index = 0; index < unitValues.length; index += 1) {
    units.add(_decodeUnit(unitValues[index], mask, r'$.units[$index]'));
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
  _expectVersion(json, r'$');
  final String deckRef = _asString(json['deckRef'], r'$.deckRef');
  final List<Object?> unitValues = _asList(json['perUnit'], r'$.perUnit');
  final List<UnitStats> perUnit = <UnitStats>[];
  for (var index = 0; index < unitValues.length; index += 1) {
    perUnit.add(_decodeUnitStats(unitValues[index], r'$.perUnit[$index]'));
  }
  return StatisticsFile(
    deckRef: deckRef,
    perUnit: List<UnitStats>.unmodifiable(perUnit),
  );
}

/// Encodes a statistics sidecar object.
Map<String, Object?> encodeStatistics(StatisticsFile statistics) {
  return <String, Object?>{
    'format': statisticsFormat,
    'version': currentFormatVersion,
    'deckRef': statistics.deckRef,
    'perUnit': statistics.perUnit.map(_encodeUnitStats).toList(growable: false),
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
  for (var index = 0; index < categoryValues.length; index += 1) {
    final CategoryDefinition category = _decodeCategory(
      categoryValues[index],
      '$path.categories[$index]',
    );
    if (!categoryIds.add(category.id)) {
      throw ValidationException(
        'Duplicate category id ${category.id}.',
        path: '$path.categories[$index].id',
      );
    }
    categories.add(category);
  }
  return LearningMask(
    name: name,
    direction1Label: direction1Label,
    direction2Label: direction2Label,
    categories: List<CategoryDefinition>.unmodifiable(categories),
  );
}

Map<String, Object?> _encodeMaskBody(LearningMask mask) {
  return <String, Object?>{
    'name': mask.name,
    'direction1Label': mask.direction1Label,
    'direction2Label': mask.direction2Label,
    'categories': mask.categories.map(_encodeCategory).toList(growable: false),
  };
}

CategoryDefinition _decodeCategory(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
  final int id = _asInt(json['id'], '$path.id');
  if (id <= 0) {
    throw ValidationException(
      'Category id must be positive.',
      path: '$path.id',
    );
  }
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
    fields.add(_decodeField(fieldValues[index], '$path.fields[$index]'));
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

FieldDefinition _decodeField(Object? value, String path) {
  final Map<String, Object?> json = _asMap(value, path);
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
    name: name,
    length: length,
    equalGroup: equalGroup,
    role1: _decodeRole(json['role1'], '$path.role1'),
    role2: _decodeRole(json['role2'], '$path.role2'),
  );
}

Map<String, Object?> _encodeField(FieldDefinition field) {
  return <String, Object?>{
    'name': field.name,
    'length': field.length,
    'equalGroup': field.equalGroup,
    'role1': field.role1.code,
    'role2': field.role2.code,
  };
}

LearningUnit _decodeUnit(Object? value, LearningMask mask, String path) {
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
  final Map<String, FieldValue> fields = <String, FieldValue>{};
  for (final MapEntry<String, Object?> entry in fieldJson.entries) {
    final FieldValue fieldValue = _decodeFieldValue(
      entry.value,
      '$path.fields.${entry.key}',
    );
    final FieldDefinition? definition = category.fieldNamed(entry.key);
    if (definition != null && fieldValue.plainText.length > definition.length) {
      throw ValidationException(
        'Field value exceeds declared length ${definition.length}.',
        path: '$path.fields.${entry.key}',
      );
    }
    fields[entry.key] = fieldValue;
  }
  return LearningUnit(
    categoryId: categoryId,
    fields: Map<String, FieldValue>.unmodifiable(fields),
  );
}

Map<String, Object?> _encodeUnit(LearningUnit unit) {
  return <String, Object?>{
    'categoryId': unit.categoryId,
    'fields': unit.fields.map(
      (String key, FieldValue value) =>
          MapEntry<String, Object?>(key, _encodeFieldValue(value)),
    ),
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
  return UnitStats(
    index: index,
    direction1: _decodeDirectionStats(json['dir1'], '$path.dir1'),
    direction2: _decodeDirectionStats(json['dir2'], '$path.dir2'),
  );
}

Map<String, Object?> _encodeUnitStats(UnitStats stats) {
  return <String, Object?>{
    'index': stats.index,
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
