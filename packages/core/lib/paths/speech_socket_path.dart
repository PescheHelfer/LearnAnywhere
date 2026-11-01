/// Where Speech Dispatcher listens: a pure function of the environment.
library;

import 'package:path/path.dart' as p;

/// The path of Speech Dispatcher's Unix socket under [environment], or null
/// when nothing in it says where that could be.
///
/// The same answer `libspeechd` reaches through GLib's runtime directory: an
/// empty variable counts as unset, a machine without `XDG_RUNTIME_DIR` falls
/// back to the user's cache directory, and that to `.cache` in the home
/// directory. `SPEECHD_ADDRESS` is deliberately not honoured.
///
/// [context] defaults to the host's. Pass [p.windows] or [p.posix] explicitly
/// to get a deterministic result, as `DeckPaths` does.
String? speechDispatcherSocketPath(
  Map<String, String> environment, {
  p.Context? context,
}) {
  final p.Context ctx = context ?? p.context;
  String? nonEmpty(String variable) {
    final String? value = environment[variable];
    return value == null || value.isEmpty ? null : value;
  }

  final String? home = nonEmpty('HOME');
  final String? directory =
      nonEmpty('XDG_RUNTIME_DIR') ??
      nonEmpty('XDG_CACHE_HOME') ??
      (home == null ? null : ctx.join(home, '.cache'));
  return directory == null
      ? null
      : ctx.join(directory, 'speech-dispatcher', 'speechd.sock');
}
