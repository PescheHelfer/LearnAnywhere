import 'package:learn_anywhere_core/core.dart';

import 'ssip_client.dart';

/// A voice as Speech Dispatcher knows it: the output module that carries it,
/// its name within that module, and the language the module reports for it.
///
/// The one place the `module:voice` id is written and read, so the two
/// directions cannot drift apart.
final class SpeechDispatcherVoice {
  /// Creates a voice as a module reported it.
  const SpeechDispatcherVoice(this.module, this.name, this.language);

  /// The voice a [SpeechVoice] listed by this engine stands for, or null for
  /// one it could not have listed.
  ///
  /// The id is split on its FIRST colon: module names hold none, and a voice
  /// name may, which then round-trips intact.
  static SpeechDispatcherVoice? of(SpeechVoice voice) {
    final int colon = voice.id.indexOf(':');
    if (colon < 0 || voice.language.isEmpty) {
      return null;
    }
    return SpeechDispatcherVoice(
      voice.id.substring(0, colon),
      voice.id.substring(colon + 1),
      voice.language,
    );
  }

  /// The output module, such as `espeak-ng`.
  final String module;

  /// The voice's name within [module], exactly as the module spells it.
  final String name;

  /// The language, exactly as the module reports it.
  final String language;

  /// This voice as the engine reports it: labelled with its module, so two
  /// modules' similarly named voices can be told apart.
  SpeechVoice get asSpeechVoice => SpeechVoice(
    id: '$module:$name',
    name: '$module: $name',
    language: language,
  );

  /// The commands that make the next message speak in this voice.
  ///
  /// In this order, because setting a language can change the voice. The name
  /// is sent bare: the daemon takes the rest of the line as the name, spaces
  /// included, and quotes would become part of it.
  List<String> get selection => <String>[
    'SET self OUTPUT_MODULE $module',
    'SET self LANGUAGE $language',
    'SET self SYNTHESIS_VOICE $name',
  ];
}

/// One output module and the voices it reported.
final class SpeechDispatcherModule {
  /// Creates a module entry.
  const SpeechDispatcherModule(this.name, this.voices, {this.refusal});

  /// The module's name, as `LIST OUTPUT_MODULES` gave it.
  final String name;

  /// Its voices in the order it reported them; empty when it reported none.
  final List<SpeechDispatcherVoice> voices;

  /// The reply that refused selecting the module or listing its voices, or
  /// null when it answered.
  final SsipReply? refusal;
}

/// Every voice of [modules] as the engine reports it, in module order.
List<SpeechVoice> speechVoicesOf(List<SpeechDispatcherModule> modules) =>
    List<SpeechVoice>.unmodifiable(<SpeechVoice>[
      for (final SpeechDispatcherModule module in modules)
        for (final SpeechDispatcherVoice voice in module.voices)
          voice.asSpeechVoice,
    ]);

/// The output module the daemon uses for a client that chose none, or null
/// when it will not say.
///
/// Must be asked before [client] sets a module, since from then on the answer
/// is the client's own choice. `GET OUTPUT_MODULE` was not in the SSIP manual
/// material the engine was written from, so a refusal is expected and is no
/// failure. Throws an [SsipException] only when no reply came at all.
Future<String?> readDefaultOutputModule(SsipClient client) async {
  final SsipReply reply = await client.command('GET OUTPUT_MODULE');
  if (!reply.isSuccess || reply.lines.isEmpty || reply.lines.first.isEmpty) {
    return null;
  }
  return reply.lines.first;
}

/// Every output module and its voices, [defaultModule] first and the rest in
/// the order the daemon reports them.
///
/// Default first because the speech policy takes the first voice that fits,
/// so **Automatic** follows how the machine was set up, while a voice the
/// learner added through another module can still be chosen. A module that
/// fails is kept, empty, rather than failing the list. A voice reporting no
/// language is left out: no field could ask for it.
///
/// Leaves [client] set to the last module listed. Throws an [SsipException]
/// only when no reply came at all.
Future<List<SpeechDispatcherModule>> listOutputModules(
  SsipClient client, {
  String? defaultModule,
}) async {
  final SsipReply listed = await client.command('LIST OUTPUT_MODULES');
  if (!listed.isSuccess) {
    return const <SpeechDispatcherModule>[];
  }
  final List<String> names = <String>[
    ...listed.lines.where((String name) => name == defaultModule),
    ...listed.lines.where((String name) => name != defaultModule),
  ];
  return <SpeechDispatcherModule>[
    for (final String name in names) await _listModule(client, name),
  ];
}

Future<SpeechDispatcherModule> _listModule(
  SsipClient client,
  String module,
) async {
  // The voice list is the current module's, so the module is set first.
  final SsipReply selected = await client.command(
    'SET self OUTPUT_MODULE $module',
  );
  final SsipReply listed = selected.isSuccess
      ? await client.command('LIST SYNTHESIS_VOICES')
      : selected;
  if (!listed.isSuccess) {
    return SpeechDispatcherModule(
      module,
      const <SpeechDispatcherVoice>[],
      refusal: listed,
    );
  }
  final List<SpeechDispatcherVoice> voices = <SpeechDispatcherVoice>[];
  for (final String line in listed.lines) {
    // `name<TAB>language<TAB>variant`. Tabs, because names hold spaces. The
    // daemon writes `none` for a language a voice does not report.
    final List<String> fields = line.split('\t');
    if (fields.length < 2 ||
        fields[0].isEmpty ||
        fields[1].isEmpty ||
        fields[1] == 'none') {
      continue;
    }
    voices.add(SpeechDispatcherVoice(module, fields[0], fields[1]));
  }
  return SpeechDispatcherModule(module, voices);
}
