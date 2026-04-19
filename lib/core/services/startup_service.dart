import 'dart:io';

/// Manages "launch at startup" for Windows by writing/removing a registry entry
/// under HKCU\Software\Microsoft\Windows\CurrentVersion\Run.
class StartupService {
  static const _valueName = 'TodoDesktop';
  static const _regKey =
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

  StartupService._();

  /// Returns true if the auto-startup entry exists in the registry.
  static Future<bool> isEnabled() async {
    final result = await Process.run(
      'reg',
      ['query', _regKey, '/v', _valueName],
      runInShell: true,
    );
    return result.exitCode == 0;
  }

  /// Adds the app executable to the Windows startup registry key.
  static Future<void> enable() async {
    final exePath = Platform.resolvedExecutable;
    await Process.run(
      'reg',
      ['add', _regKey, '/v', _valueName, '/t', 'REG_SZ', '/d', exePath, '/f'],
      runInShell: true,
    );
  }

  /// Removes the app executable from the Windows startup registry key.
  static Future<void> disable() async {
    await Process.run(
      'reg',
      ['delete', _regKey, '/v', _valueName, '/f'],
      runInShell: true,
    );
  }
}
