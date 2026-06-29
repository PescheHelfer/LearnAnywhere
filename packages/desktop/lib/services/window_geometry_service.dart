import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Persists and restores window position, size, and maximized state.
///
/// Call [restoreGeometry] inside `windowManager.waitUntilReadyToShow` before
/// showing the window. Add a [WindowListener] that calls [saveGeometry] on
/// resize/move/maximize events. Call [dispose] when the listener is removed.
final class WindowGeometryService {
  static const String _keyX = 'window_x';
  static const String _keyY = 'window_y';
  static const String _keyWidth = 'window_width';
  static const String _keyHeight = 'window_height';
  static const String _keyMaximized = 'window_maximized';

  Timer? _saveTimer;

  /// Restores the previously saved window position, size, and maximized state.
  ///
  /// Must be called inside `windowManager.waitUntilReadyToShow` before the
  /// window is shown. On first run (no stored values) this is a no-op and the
  /// `WindowOptions.center` default takes effect.
  Future<void> restoreGeometry() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final double? x = prefs.getDouble(_keyX);
    final double? y = prefs.getDouble(_keyY);
    final double? width = prefs.getDouble(_keyWidth);
    final double? height = prefs.getDouble(_keyHeight);
    final bool maximized = prefs.getBool(_keyMaximized) ?? false;

    if (x == null && y == null && width == null && height == null) {
      return; // first run — let WindowOptions.center apply
    }

    if (width != null && height != null) {
      await windowManager.setSize(Size(width, height));
    }

    if (x != null && y != null) {
      final double w = width ?? 1024;
      final double h = height ?? 700;
      if (_isOnScreen(x, y, w, h)) {
        await windowManager.setPosition(Offset(x, y));
      } else {
        await windowManager.center();
      }
    }

    if (maximized) {
      await windowManager.maximize();
    }
  }

  bool _isOnScreen(double x, double y, double w, double h) {
    final Iterable<ui.Display> displays =
        ui.PlatformDispatcher.instance.displays;
    if (displays.isEmpty) return true;
    const double minVisible = 100.0;
    for (final ui.Display display in displays) {
      final double dpr = display.devicePixelRatio;
      final double screenW = display.size.width / dpr;
      final double screenH = display.size.height / dpr;
      if (x + minVisible <= screenW &&
          y + minVisible <= screenH &&
          x + w > 0 &&
          y + h > 0) {
        return true;
      }
    }
    return false;
  }

  /// Schedules a geometry save, debounced to at most once per second.
  void saveGeometry() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), _doSave);
  }

  Future<void> _doSave() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (await windowManager.isMaximized()) {
      // Only record that the window is maximized; keep the pre-maximize
      // position/size so restoring from a maximized state gives back the
      // correct normal bounds.
      await prefs.setBool(_keyMaximized, true);
      return;
    }
    final Offset position = await windowManager.getPosition();
    final Size size = await windowManager.getSize();
    await prefs.setDouble(_keyX, position.dx);
    await prefs.setDouble(_keyY, position.dy);
    await prefs.setDouble(_keyWidth, size.width);
    await prefs.setDouble(_keyHeight, size.height);
    await prefs.setBool(_keyMaximized, false);
  }

  /// Cancels any pending debounced save. Call from the owning widget's dispose.
  void dispose() {
    _saveTimer?.cancel();
  }
}
