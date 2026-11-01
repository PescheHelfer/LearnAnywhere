import 'package:learn_anywhere_core/core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Asserted against both explicit contexts, like `deck_paths_test.dart`, so the
/// expectations hold on whichever host runs the suite.
void main() {
  group('speechDispatcherSocketPath', () {
    test('sits in the runtime directory when there is one', () {
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'XDG_RUNTIME_DIR': '/run/user/1000',
          'XDG_CACHE_HOME': '/home/pesche/.mycache',
          'HOME': '/home/pesche',
        }, context: p.posix),
        '/run/user/1000/speech-dispatcher/speechd.sock',
      );
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'XDG_RUNTIME_DIR': r'C:\run',
        }, context: p.windows),
        r'C:\run\speech-dispatcher\speechd.sock',
      );
    });

    test('falls back to the cache directory without a runtime directory', () {
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'XDG_CACHE_HOME': '/home/pesche/.mycache',
          'HOME': '/home/pesche',
        }, context: p.posix),
        '/home/pesche/.mycache/speech-dispatcher/speechd.sock',
      );
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'XDG_CACHE_HOME': r'C:\cache',
        }, context: p.windows),
        r'C:\cache\speech-dispatcher\speechd.sock',
      );
    });

    test('falls back to .cache in the home directory last', () {
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'HOME': '/home/pesche',
        }, context: p.posix),
        '/home/pesche/.cache/speech-dispatcher/speechd.sock',
      );
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'HOME': r'C:\Users\pesche',
        }, context: p.windows),
        r'C:\Users\pesche\.cache\speech-dispatcher\speechd.sock',
      );
    });

    test('treats an empty variable as an unset one', () {
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'XDG_RUNTIME_DIR': '',
          'XDG_CACHE_HOME': '',
          'HOME': '/home/pesche',
        }, context: p.posix),
        '/home/pesche/.cache/speech-dispatcher/speechd.sock',
      );
    });

    test('keeps a backslash in a POSIX directory name', () {
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'XDG_RUNTIME_DIR': r'/run/odd\name',
        }, context: p.posix),
        r'/run/odd\name/speech-dispatcher/speechd.sock',
      );
    });

    test('is null when nothing says where the socket could be', () {
      for (final p.Context ctx in <p.Context>[p.windows, p.posix]) {
        expect(
          speechDispatcherSocketPath(const <String, String>{}, context: ctx),
          isNull,
        );
      }
    });

    test('does not honour SPEECHD_ADDRESS', () {
      expect(
        speechDispatcherSocketPath(const <String, String>{
          'SPEECHD_ADDRESS': 'unix_socket:/tmp/elsewhere.sock',
          'XDG_RUNTIME_DIR': '/run/user/1000',
        }, context: p.posix),
        '/run/user/1000/speech-dispatcher/speechd.sock',
      );
    });
  });
}
