/// Says one sample per language through Speech Dispatcher, logging everything.
///
/// The first thing to run on a Linux machine when speech is silent, because it
/// explains a failure without a debugger: every line sent and received is
/// printed, using the same client the program speaks through. From the
/// repository root:
///
///     dart run packages/ui_kit/tool/ssip_diagnostic.dart
///
/// Exits with 0 when all samples were spoken and 1 otherwise.
library;

import 'dart:async';
import 'dart:io';

import 'package:learn_anywhere_core/core.dart';
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

/// Speaks the samples through [connect], passing every line to [log].
///
/// Returns whether each sample was said to its end in its own language, waiting
/// at most [sampleLimit] for each. Never throws: a failure is what this reports.
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
    for (final MapEntry<String, String> sample in _samples.entries) {
      final SsipReply language = await client.command(
        'SET self LANGUAGE ${sample.key}',
      );
      if (!language.isSuccess) {
        // Still spoken: hearing what comes out instead is worth knowing.
        log('Language ${sample.key} was refused: $language');
        allSpoken = false;
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
