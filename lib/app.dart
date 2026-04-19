import 'package:flutter/material.dart';
import 'features/todo/ui/pages/home_page.dart';
import 'shared/theme.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  /// Global navigator key – used by SchedulerService to get a context
  /// that lives below MaterialApp (and thus has access to Overlay).
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo Desktop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const HomePage(),
    );
  }
}
