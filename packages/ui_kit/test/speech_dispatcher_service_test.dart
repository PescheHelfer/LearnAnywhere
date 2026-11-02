import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/src/speech/speech_dispatcher_service.dart';

/// A process that ends when [exit] completes, and has nothing else.
final class _FakeProcess implements Process {
  final Completer<int> exit = Completer<int>();

  @override
  Future<int> get exitCode => exit.future;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One call of the process starter.
typedef _Started = ({
  String executable,
  List<String> arguments,
  Map<String, String>? environment,
  bool includeParentEnvironment,
});

void main() {
  const Map<String, String> appImage = <String, String>{
    'HOME': '/home/learner',
    'XDG_RUNTIME_DIR': '/run/user/1000',
    'PATH': '/tmp/.mount_Learn/usr/bin:/usr/bin',
    'LD_LIBRARY_PATH': '/tmp/.mount_Learn/usr/lib',
    'APPIMAGE': '/home/learner/LearnAnywhere.AppImage',
  };

  late List<_Started> started;
  late _FakeProcess process;

  Future<Process> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    started.add((
      executable: executable,
      arguments: arguments,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    ));
    return process;
  }

  setUp(() {
    started = <_Started>[];
    process = _FakeProcess()..exit.complete(0);
  });

  test('spawns the service on the socket the program connects to', () async {
    await startSpeechDispatcher(environment: appImage, run: run);

    expect(started.single.executable, 'speech-dispatcher');
    expect(started.single.arguments, <String>[
      '--spawn',
      '--communication-method',
      'unix_socket',
      '--socket-path',
      speechDispatcherSocketPath(appImage)!,
    ]);
  });

  test('the service gets the environment without LD_LIBRARY_PATH', () async {
    await startSpeechDispatcher(environment: appImage, run: run);

    // Only a complete environment of our own keeps the variable out: a map
    // merged into the parent's would hand the bundled libraries over anyway.
    expect(started.single.includeParentEnvironment, isFalse);
    expect(started.single.environment, <String, String>{
      'HOME': '/home/learner',
      'XDG_RUNTIME_DIR': '/run/user/1000',
      'PATH': '/tmp/.mount_Learn/usr/bin:/usr/bin',
      'APPIMAGE': '/home/learner/LearnAnywhere.AppImage',
    });
  });

  test('a missing binary completes quietly', () async {
    final Future<void> start = startSpeechDispatcher(
      environment: appImage,
      run:
          (
            String executable,
            List<String> arguments, {
            Map<String, String>? environment,
            bool includeParentEnvironment = true,
            ProcessStartMode mode = ProcessStartMode.normal,
          }) => throw ProcessException(executable, arguments, 'not found', 2),
    );

    await expectLater(start, completes);
  });

  test('an environment naming no socket starts nothing', () async {
    await startSpeechDispatcher(
      environment: const <String, String>{'PATH': '/usr/bin'},
      run: run,
    );

    expect(started, isEmpty);
  });

  test('a start that never finishes is not waited on for ever', () async {
    process = _FakeProcess();

    await startSpeechDispatcher(
      environment: appImage,
      run: run,
      limit: const Duration(milliseconds: 20),
    );

    expect(started, hasLength(1));
  });
}
