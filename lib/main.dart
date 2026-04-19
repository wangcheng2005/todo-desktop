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

  // Initialize window manager
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

  // Initialize storage
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

    // Initialize tray after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
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

  @override
  void onWindowClose() async {
    // Minimize to tray instead of closing
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return const TodoApp();
  }
}
