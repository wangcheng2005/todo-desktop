import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class TrayService {
  final SystemTray _tray = SystemTray();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Use embedded app icon
    String iconPath = Platform.resolvedExecutable
        .replaceAll(RegExp(r'[^\\\/]+$'), '')
        .replaceAll('\\', '/');
    // Fallback: use a default icon from flutter assets or ico
    String trayIconPath = '${iconPath}data/flutter_assets/assets/icons/app_icon.ico';
    
    // If custom icon doesn't exist, use the runner icon
    if (!File(trayIconPath).existsSync()) {
      // Try the runner resource icon
      trayIconPath = '';  // system_tray will use default icon when empty on Windows
    }

    await _tray.initSystemTray(
      title: 'Todo Desktop',
      iconPath: trayIconPath,
      toolTip: 'Todo Desktop - 待办事项管理',
    );

    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '打开应用',
        onClicked: (_) => _showWindow(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (_) => _exitApp(),
      ),
    ]);
    await _tray.setContextMenu(menu);

    _tray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick ||
          eventName == kSystemTrayEventDoubleClick) {
        _showWindow();
      } else if (eventName == kSystemTrayEventRightClick) {
        _tray.popUpContextMenu();
      }
    });

    _initialized = true;
    debugPrint('[TrayService] System tray initialized');
  }

  Future<void> _showWindow() async {
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _exitApp() async {
    await _tray.destroy();
    exit(0);
  }

  Future<void> destroy() async {
    if (_initialized) {
      await _tray.destroy();
      _initialized = false;
    }
  }
}
