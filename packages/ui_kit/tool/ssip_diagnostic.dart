/// Lists Speech Dispatcher's voices and says one sample per language, logging
/// everything.
///
/// The first thing to run on a Linux machine when speech is silent, because it
/// explains a failure without a debugger: every line sent and received is
/// printed, using the same client, the same voice list and the same voice
/// choice as the program, so each sample is said by the voice **Automatic**
/// would pick. From the repository root:
///
///     dart run packages/ui_kit/tool/ssip_diagnostic.dart
///
/// Exits with 0 when all samples were spoken and 1 otherwise.
library;

import 'dart:async';
import 'dart:io';

import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/src/speech/speech_dispatcher_voices.dart';
import 'package:learn_anywhere_ui_kit/src/speech/ssip_client.dart';

const Map<String, String> _samples = <String, String>{
  'en': 'A naïve café, spoken in English.',
  'de': 'Grüezi, schöne Grüsse aus der Schweiz.',
  'fr': 'Le français est très bien prononcé.',
  'it': 'Perché no? È così che si dice.',
};

Future<void> main() async {
  final String? path = speechDispatcherSocketPath(Platform.environment);
  stdout.writeln('Socket: ${path ?? 'none, the environment names no folder'}');
  final bool worked = await runSsipDiagnostic(
    connectToSpeechDispatcher,
    stdout.writeln,
  );
  stdout.writeln(worked ? 'All samples spoken.' : 'Not all samples spoken.');
  exitCode = worked ? 0 : 1;
}

/// Lists the voices and speaks the samples through [connect], passing every
/// line to [log].
///
/// Returns whether each sample was said to its end by a voice for its own
/// language, waiting at most [sampleLimit] for each. Never throws: a failure
/// is what this reports.
Future<bool> runSsipDiagnostic(
  SsipConnector connect,
  void Function(String line) log, {
  Duration sampleLimit = const Duration(seconds: 30),
}) async {
  final SsipClient client;
  try {
    client = await SsipClient.open(connect, onTraffic: log);
  } on IOException catch (error) {
    log('No connection: $error');
    return false;
  } on SsipException catch (error) {
    log('No connection: $error');
    return false;
  }
  // Listening from the start, since a short word can be over before the reply
  // giving its id has been read.
  final Set<int> ended = <int>{};
  final StreamSubscription<SsipEvent> events = client.events.listen((
    SsipEvent event,
  ) {
    if (event.kind == SsipEventKind.ended) {
      ended.add(event.messageId);
    }
  });
  bool allSpoken = true;
  try {
    // Before anything sets a module, as the engine asks it.
    final String? defaultModule = await readDefaultOutputModule(client);
    log('Default module: ${defaultModule ?? 'not reported'}');
    final List<SpeechDispatcherModule> modules = await listOutputModules(
      client,
      defaultModule: defaultModule,
    );
    final List<SpeechVoice> voices = speechVoicesOf(modules);
    _logModules(modules, log);
    _logVoicesByLanguage(voices, log);
    for (final MapEntry<String, String> sample in _samples.entries) {
      final SpeechVoice? voice = resolveSpeechVoice(sample.key, voices);
      final SpeechDispatcherVoice? chosen = voice == null
          ? null
          : SpeechDispatcherVoice.of(voice);
      final List<String> selection;
      if (chosen == null) {
        // Still spoken: hearing what the daemon makes of it is worth knowing.
        log(
          'No voice for ${sample.key}, said by the module set last, only the language set',
        );
        allSpoken = false;
        selection = <String>['SET self LANGUAGE ${sample.key}'];
      } else {
        log('${sample.key}: ${chosen.asSpeechVoice.name} (${chosen.language})');
        selection = chosen.selection;
      }
      for (final String command in selection) {
        final SsipReply reply = await client.command(command);
        if (!reply.isSuccess) {
          // Still spoken, for the same reason.
          log('Refused "$command": $reply');
          allSpoken = false;
        }
      }
      final int id = await client.speak(sample.value);
      final DateTime deadline = DateTime.now().add(sampleLimit);
      while (!ended.contains(id) && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      if (!ended.contains(id)) {
        log('No END for message $id within $sampleLimit');
        allSpoken = false;
      }
    }
  } on SsipException catch (error) {
    log('Stopped: $error');
    allSpoken = false;
  }
  await events.cancel();
  client.close();
  return allSpoken;
}

/// One line per module, in the order the engine lists them.
void _logModules(
  List<SpeechDispatcherModule> modules,
  void Function(String line) log,
) {
  if (modules.isEmpty) {
    log('No output modules');
  }
  for (final SpeechDispatcherModule module in modules) {
    final int count = module.voices.length;
    final SsipReply? refusal = module.refusal;
    log(
      refusal != null
          ? 'Module ${module.name}: no voices, $refusal'
          : 'Module ${module.name}: $count ${count == 1 ? 'voice' : 'voices'}',
    );
  }
}

/// Each reported language, sorted, with its voices in list order beneath it.
void _logVoicesByLanguage(
  List<SpeechVoice> voices,
  void Function(String line) log,
) {
  final Map<String, List<SpeechVoice>> byLanguage =
      <String, List<SpeechVoice>>{};
  for (final SpeechVoice voice in voices) {
    (byLanguage[voice.language] ??= <SpeechVoice>[]).add(voice);
  }
  for (final String language in byLanguage.keys.toList()..sort()) {
    log('Voices for $language:');
    for (final SpeechVoice voice in byLanguage[language]!) {
      log('  ${voice.name}');
    }
  }
}
