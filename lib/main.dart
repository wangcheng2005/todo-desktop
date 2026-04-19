import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/storage/storage_service.dart';
import 'core/tray/tray_service.dart';
import 'core/scheduler/scheduler_service.dart';
import 'features/todo/provider/todo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kill stale instances of this app (zombie processes holding Hive locks).
  await _killStaleInstances();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(600, 400),
    center: true,
    title: 'Todo Desktop',
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final storage = StorageService();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: _AppWithServices(storage: storage),
    ),
  );
}

class _AppWithServices extends ConsumerStatefulWidget {
  final StorageService storage;
  const _AppWithServices({required this.storage});

  @override
  ConsumerState<_AppWithServices> createState() => _AppWithServicesState();
}

class _AppWithServicesState extends ConsumerState<_AppWithServices>
    with WindowListener {
  late TrayService _trayService;
  late SchedulerService _schedulerService;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);

    _trayService = TrayService();
    _schedulerService = SchedulerService(widget.storage);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initServices());
  }

  Future<void> _initServices() async {
    await _trayService.init();
    _schedulerService.start(
      onMarkComplete: (id) {
        ref.read(todoListProvider.notifier).toggleComplete(id);
      },
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _schedulerService.stop();
    _trayService.destroy();
    super.dispose();
  }

  /// Close button → hide main window to tray.
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return const TodoApp();
  }
}

/// Kill other running instances of todo_desktop.exe (stale / zombie) so that
/// Hive lock files are released. Skips the current process.
Future<void> _killStaleInstances() async {
  if (!Platform.isWindows) return;
  final myPid = pid;
  try {
    final result = await Process.run(
      'tasklist',
      ['/fi', 'imagename eq todo_desktop.exe', '/fo', 'csv', '/nh'],
    );
    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      // CSV format: "todo_desktop.exe","12345",...
      final match = RegExp(r'"todo_desktop\.exe"\s*,\s*"(\d+)"').firstMatch(line);
      if (match != null) {
        final stalePid = int.parse(match.group(1)!);
        if (stalePid != myPid) {
          Process.runSync('taskkill', ['/f', '/pid', '$stalePid']);
          debugPrint('[main] Killed stale instance PID $stalePid');
        }
      }
    }
  } catch (e) {
    debugPrint('[main] Failed to kill stale instances: $e');
  }
}