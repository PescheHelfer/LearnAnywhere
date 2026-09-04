/// The spoken-language vocabulary: the curated tag list a mask author picks
/// from, and the shape rules any typed tag must satisfy.
///
/// Pure Dart, no I/O: the same list and the same validation serve both shells,
/// so a mask authored on the desktop means exactly the same thing on the phone.
library;

/// One entry of the curated spoken-language list.
final class SpokenLanguageOption {
  /// Creates a catalogue entry.
  const SpokenLanguageOption(this.tag, this.label);

  /// The BCP-47 tag stored in the mask, for example `fr-FR`.
  final String tag;

  /// The name shown to the author, written in the language itself.
  ///
  /// Endonyms are deliberate: a language list that names each language the way
  /// its own speakers write it needs no translation, and stays correct
  /// whichever interface language is active.
  final String label;
}

/// The empty tag: this field has no spoken language and is never read aloud.
///
/// It is the default for every field, which is what keeps every mask that
/// exists today behaving exactly as it does now. It is NOT a language tag —
/// [isValidSpokenLanguageTag] rejects it.
const String noSpokenLanguage = '';

/// The curated tags offered in the mask editor.
///
/// The four languages this program is built to drill (German, English, French,
/// Italian) plus the regional distinctions a learner actually cares about
/// hearing — British against American English, Austrian and Swiss German
/// against the German of Germany, Canadian against France French. Anything else
/// is typed by hand; see [isValidSpokenLanguageTag].
const List<SpokenLanguageOption> spokenLanguageCatalog = <SpokenLanguageOption>[
  SpokenLanguageOption('de-DE', 'Deutsch (Deutschland)'),
  SpokenLanguageOption('de-AT', 'Deutsch (Österreich)'),
  SpokenLanguageOption('de-CH', 'Deutsch (Schweiz)'),
  SpokenLanguageOption('en-GB', 'English (United Kingdom)'),
  SpokenLanguageOption('en-US', 'English (United States)'),
  SpokenLanguageOption('fr-FR', 'Français (France)'),
  SpokenLanguageOption('fr-CA', 'Français (Canada)'),
  SpokenLanguageOption('it-IT', 'Italiano (Italia)'),
];

/// `language[-Script][-REGION]`, the only shape this app stores.
///
/// Deliberately narrower than the whole of BCP-47: extensions, private-use
/// subtags and variants say nothing a speech engine can act on here, and
/// accepting them would only invite tags no voice will ever match.
final RegExp _tagShape = RegExp(
  r'^[a-zA-Z]{2,3}(-[a-zA-Z]{4})?(-([a-zA-Z]{2}|[0-9]{3}))?$',
);

/// Whether [tag] is shaped like a spoken-language tag.
///
/// Shape only — no registry is consulted, so `zz-ZZ` passes. The point is to
/// catch `french` or `fr_FR`, not to police which languages exist.
bool isValidSpokenLanguageTag(String tag) => _tagShape.hasMatch(tag);

/// Returns [tag] in conventional BCP-47 casing (`fr-FR`, `zh-Hant-TW`).
///
/// Casing carries no meaning in a language tag, so a typed `FR-fr` is stored
/// the same way the catalogue writes it and compares equal to it. Returns [tag]
/// unchanged when it is not [isValidSpokenLanguageTag].
String normalizeSpokenLanguageTag(String tag) {
  if (!isValidSpokenLanguageTag(tag)) {
    return tag;
  }
  final List<String> parts = tag.split('-');
  final StringBuffer buffer = StringBuffer(parts.first.toLowerCase());
  for (final String part in parts.skip(1)) {
    buffer.write('-');
    if (part.length == 4) {
      // A script subtag is title case: `Hant`, `Latn`.
      buffer
        ..write(part.substring(0, 1).toUpperCase())
        ..write(part.substring(1).toLowerCase());
    } else {
      buffer.write(part.toUpperCase());
    }
  }
  return buffer.toString();
}

/// Returns [tag] in the one spelling this app compares and stores by.
///
/// [normalizeSpokenLanguageTag] with a host's underscore form (`fr_FR`, which
/// Android's locales produce) folded onto the hyphen form first, so a tag from
/// a mask, from a settings file and from a host's voice list all reduce to the
/// same string.
String canonicalSpokenLanguageTag(String tag) =>
    normalizeSpokenLanguageTag(tag.replaceAll('_', '-'));

/// The primary language subtag of [tag] — `fr` of `fr-CA`.
String baseSpokenLanguage(String tag) =>
    canonicalSpokenLanguageTag(tag).split('-').first.toLowerCase();

/// The phrase spoken when a voice for [language] is auditioned.
///
/// Written in the language being auditioned, because a voice is being judged
/// on how it says that language and not on how it copes with another one. The
/// four languages this program is built to drill have their own phrase; a
/// hand-typed tag falls back to the English one, which still lets the voice be
/// heard and compared with its neighbours in the list.
String speechSampleFor(String language) {
  return _speechSamples[baseSpokenLanguage(language)] ?? _speechSamples['en']!;
}

/// One sample phrase per base language. Short, ordinary sentences: the point
/// is to hear the voice, not to test the engine.
const Map<String, String> _speechSamples = <String, String>{
  'de': 'Guten Tag, so klingt diese Stimme.',
  'en': 'Good day, this is how this voice sounds.',
  'fr': 'Bonjour, voici comment sonne cette voix.',
  'it': 'Buongiorno, ecco come suona questa voce.',
};

/// Whether [tag] is one of the [spokenLanguageCatalog] entries.
bool isCatalogSpokenLanguage(String tag) {
  return _catalogEntryFor(tag) != null;
}

/// The label a machine-readable spoken-language [tag] is shown under: the
/// mask editor's own catalog wording plus the bare tag, or just the tag for
/// one typed by hand and not in the catalog.
///
/// Shared by every screen that names a spoken language to a person — the
/// mask editor's language picker and both shells' Speech settings screens —
/// so they cannot drift into showing different text for the same tag.
String spokenLanguageLabel(String tag) {
  final SpokenLanguageOption? option = _catalogEntryFor(tag);
  return option == null ? tag : '${option.label} ($tag)';
}

SpokenLanguageOption? _catalogEntryFor(String tag) {
  for (final SpokenLanguageOption option in spokenLanguageCatalog) {
    if (option.tag == tag) {
      return option;
    }
  }
  return null;
}
