import 'package:flutter/material.dart';
import '../../../../core/services/startup_service.dart';
import '../../../../shared/theme.dart';

/// Settings dialog — currently contains only the auto-startup toggle.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _autoStartup = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await StartupService.isEnabled();
    if (mounted) {
      setState(() {
        _autoStartup = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggleAutoStartup(bool value) async {
    setState(() => _autoStartup = value);
    if (value) {
      await StartupService.enable();
    } else {
      await StartupService.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  topRight: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '设置',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildSection(
                      title: '启动',
                      children: [
                        _SettingsTile(
                          icon: Icons.rocket_launch_rounded,
                          iconColor: AppTheme.primary,
                          title: '开机启动',
                          subtitle: '登录 Windows 时自动启动 Todo Desktop',
                          trailing: Switch(
                            value: _autoStartup,
                            onChanged: _toggleAutoStartup,
                            activeColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: children),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
