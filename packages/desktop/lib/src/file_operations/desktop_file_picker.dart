import 'dart:io';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:path/path.dart' as p;

/// Bridges desktop file operations to the native OS open/save dialogs.
///
/// This class deliberately holds no user-facing strings: every label shown to
/// the user (the type-group caption in the filter dropdown) is passed in by the
/// caller so it can be sourced from the i18n catalog. The class only resolves
/// a path and never touches serialization, keeping all business logic in core.
final class DesktopFilePicker {
  /// Creates a desktop file picker.
  const DesktopFilePicker();

  /// Shows a native "Open file" dialog filtered to [extension].
  ///
  /// [typeLabel] is the localized caption for the extension filter and
  /// [initialDirectory] is where the dialog opens. Returns the chosen absolute
  /// path, or null when the user cancels.
  Future<String?> openPath({
    required String extension,
    required String typeLabel,
    String? initialDirectory,
  }) async {
    final fs.XFile? file = await fs.openFile(
      acceptedTypeGroups: <fs.XTypeGroup>[
        fs.XTypeGroup(label: typeLabel, extensions: <String>[extension]),
      ],
      initialDirectory: initialDirectory,
    );
    return file?.path;
  }

  /// Shows a native "Save file" dialog filtered to [extension], pre-filling
  /// [suggestedName] as the file name.
  ///
  /// Returns the chosen absolute path, or null when the user cancels.
  Future<String?> savePath({
    required String extension,
    required String typeLabel,
    required String suggestedName,
    String? initialDirectory,
  }) async {
    final fs.FileSaveLocation? location = await fs.getSaveLocation(
      acceptedTypeGroups: <fs.XTypeGroup>[
        fs.XTypeGroup(label: typeLabel, extensions: <String>[extension]),
      ],
      initialDirectory: initialDirectory,
      suggestedName: suggestedName,
    );
    return location?.path;
  }

  /// Shows a native "Choose folder" dialog, returning the chosen absolute
  /// directory path or null when the user cancels.
  Future<String?> pickDirectory({String? initialDirectory}) async {
    return fs.getDirectoryPath(initialDirectory: initialDirectory);
  }

  /// Returns the folder the dialog should open in.
  ///
  /// Uses the folder of [currentPath] when a file is loaded, otherwise the
  /// user's documents folder (Windows) or home folder, falling back to the
  /// current working directory.
  String? initialDirectory(String? currentPath) {
    if (currentPath != null) {
      final String directory = directoryOf(currentPath);
      if (directory.isNotEmpty) {
        return directory;
      }
    }
    return _documentsOrHome();
  }

  /// Returns the file name portion of [path] (without its directory).
  ///
  /// Uses the host's path rules, so on Linux a backslash inside a file name is
  /// kept as part of the name instead of being mistaken for a separator.
  String fileNameOf(String path) => p.basename(path);

  /// Returns the directory portion of [path], or an empty string when [path]
  /// has no directory component.
  String directoryOf(String path) {
    final String directory = p.dirname(path);
    // `p.dirname` reports '.' for a bare file name; callers here treat "no
    // directory" as the empty string and fall back to the documents folder.
    return directory == '.' && !path.startsWith('.') ? '' : directory;
  }

  String? _documentsOrHome() {
    final Map<String, String> env = Platform.environment;
    final String? base = Platform.isWindows
        ? env['USERPROFILE']
        : env['HOME'];
    if (base == null || base.isEmpty) {
      return null;
    }
    // Prefer the user's documents folder on both platforms, falling back to the
    // profile/home root when it doesn't exist (a Linux desktop may localize or
    // omit ~/Documents entirely).
    final Directory documents = Directory(p.join(base, 'Documents'));
    return documents.existsSync() ? documents.path : base;
  }
}
