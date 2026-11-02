import 'dart:async';
import 'dart:io';

import 'package:learn_anywhere_core/core.dart';

import 'ssip_client.dart';

/// Starts Speech Dispatcher when nothing answered. Injected, so tests can see
/// that it was asked for without anything being run.
///
/// A service that cannot be started is simply not there. [startSpeechDispatcher]
/// never throws; one that does, say with a missing binary's
/// [ProcessException], fails the connection attempt and nothing more.
typedef SpeechDispatcherStarter = Future<void> Function();

/// Runs a program, shaped like [Process.start]. Injected, so a test can see
/// the command and the environment the service would be given.
typedef ProcessStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      Map<String, String>? environment,
      bool includeParentEnvironment,
      ProcessStartMode mode,
    });

/// Connects through [connect]; when nothing answers there, runs [start] once
/// and connects again.
///
/// A daemon that answers and then refuses the handshake is not started
/// again: it is running, and a second one would not help. Throws what
/// [SsipClient.open] throws when the second attempt fails as well, and
/// whatever [start] throws.
Future<SsipClient> openSpeechDispatcher(
  SsipConnector connect, {
  SpeechDispatcherStarter start = startSpeechDispatcher,
  Duration commandTimeout = SsipClient.defaultCommandTimeout,
  void Function(String line)? onTraffic,
}) async {
  Future<SsipClient> attempt() => SsipClient.open(
    connect,
    commandTimeout: commandTimeout,
    onTraffic: onTraffic,
  );
  try {
    return await attempt();
  } on IOException {
    await start();
    return attempt();
  }
}

/// Starts the service of the user running this program, if it is installed,
/// on the socket [connectToSpeechDispatcher] looks for. Completes once the
/// start has finished, or after [limit], whichever comes first.
///
/// The command is the one `libspeechd` runs. With `--spawn` it hands the
/// daemon over to the background and ends, or ends at once when a daemon is
/// already running, so it is harmless to run when unsure.
///
/// [environment] defaults to this program's, without `LD_LIBRARY_PATH`:
/// inside the AppImage that names the bundled libraries, which must not reach
/// a daemon of the host's. Never throws; a missing `speech-dispatcher` is the
/// same as a service that would not start.
Future<void> startSpeechDispatcher({
  Map<String, String>? environment,
  ProcessStarter run = Process.start,
  Duration limit = const Duration(seconds: 10),
}) async {
  final Map<String, String> host = environment ?? Platform.environment;
  final String? socket = speechDispatcherSocketPath(host);
  if (socket == null) {
    return;
  }
  try {
    final Process process = await run(
      'speech-dispatcher',
      <String>[
        '--spawn',
        '--communication-method',
        'unix_socket',
        '--socket-path',
        socket,
      ],
      // Complete and not merged into the parent's, since a merge would hand
      // the removed variable back.
      environment: Map<String, String>.of(host)..remove('LD_LIBRARY_PATH'),
      includeParentEnvironment: false,
      // Not piped: a daemon that kept the pipes open would keep them busy
      // long after the start was over.
      mode: ProcessStartMode.inheritStdio,
    );
    await process.exitCode.timeout(limit);
  } on ProcessException {
    // Not installed. The next call looks again.
  } on TimeoutException {
    // Still starting, perhaps. The connection attempt that follows decides.
  }
}
