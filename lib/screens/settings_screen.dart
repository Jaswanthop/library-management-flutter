import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/library_store.dart';
import '../dialogs/confirm_dialog.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';
import '../widgets/common.dart';

/// App preferences, library profile and data tools.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  Future<void> _export(BuildContext context) async {
    final LibraryStore store = LibraryScope.read(context);
    await Clipboard.setData(ClipboardData(text: store.booksAsCsv()));
    if (context.mounted) {
      showToast(
        context,
        'Catalogue CSV copied to the clipboard.',
        icon: Icons.file_download_done_rounded,
      );
    }
  }

  Future<void> _reset(BuildContext context) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Reset demo data?',
      message:
          'Every book, member and loan you have added will be replaced with '
          'the sample library. This cannot be undone.',
      confirmLabel: 'Reset library',
    );
    if (!confirmed || !context.mounted) return;
    LibraryScope.read(context).resetToDemoData();
    showToast(context, 'Demo library restored.', icon: Icons.restore_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final LibraryStore store = LibraryScope.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PageHeader(
                title: 'Settings',
                subtitle:
                    'Appearance, library profile and catalogue tools for this workspace.',
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionTitle(
                      title: 'Appearance',
                      caption: 'Choose how Shelfwise looks on this device.',
                    ),
                    const SizedBox(height: 18),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeMode,
                      builder: (BuildContext context, ThemeMode mode, Widget? _) {
                        return SegmentedButton<ThemeMode>(
                          segments: const <ButtonSegment<ThemeMode>>[
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              label: Text('System'),
                              icon: Icon(Icons.brightness_auto_outlined, size: 17),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_outlined, size: 17),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_outlined, size: 17),
                            ),
                          ],
                          selected: <ThemeMode>{mode},
                          showSelectedIcon: false,
                          onSelectionChanged: (Set<ThemeMode> selection) {
                            themeMode.value = selection.first;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.infoSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.palette_outlined,
                              size: 18, color: colors.info),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Shelfwise uses a warm paper palette by day and an '
                              'ink-green palette at night. The choice is remembered '
                              'while the tab stays open.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: colors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionTitle(
                      title: 'Library profile',
                      caption: 'Details shown across the workspace.',
                    ),
                    const SizedBox(height: 18),
                    _InfoRow(
                      icon: Icons.local_library_outlined,
                      label: 'Library',
                      value: 'Shelfwise Central Library',
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: '12 Reading Room Lane, Bengaluru',
                    ),
                    _InfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Hours',
                      value: 'Mon–Sat · 9:00 – 19:00',
                    ),
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      label: 'Contact',
                      value: 'frontdesk@shelfwise.example',
                    ),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Librarian',
                      value: 'Signed in as the demo librarian',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionTitle(
                      title: 'Catalogue tools',
                      caption:
                          '${store.totalTitles} titles · ${store.members.length} members · '
                          '${store.loans.length} loan records',
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => _export(context),
                          icon: const Icon(Icons.file_download_outlined,
                              size: 18),
                          label: const Text('Copy catalogue as CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _reset(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.danger,
                            side: BorderSide(color: colors.dangerSoft),
                          ),
                          icon: const Icon(Icons.restore_rounded, size: 18),
                          label: const Text('Reset demo data'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Shelfwise keeps everything in memory for the current '
                      'session. Refreshing the browser restores the sample library.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionTitle(
                      title: 'About',
                      caption: 'Shelfwise · Library Management',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                theme.colorScheme.primary,
                                AppTheme.brand,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_stories_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Version 1.0.0',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A responsive Flutter web app for catalogue, '
                                'membership and loan management.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.7))),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: colors.muted),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: colors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
