import 'package:flutter/material.dart';

import '../data/library_store.dart';
import '../dialogs/book_dialog.dart';
import '../dialogs/loan_dialog.dart';
import '../screens/books_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/loans_screen.dart';
import '../screens/members_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

/// Responsive chrome: sidebar, optional rail, drawer on phones, and a top bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavDestination> _destinations = <_NavDestination>[
    _NavDestination(
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
    ),
    _NavDestination(
      label: 'Catalogue',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
    ),
    _NavDestination(
      label: 'Members',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group_rounded,
    ),
    _NavDestination(
      label: 'Loans',
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz_rounded,
    ),
    _NavDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  late final List<Widget> _screens = <Widget>[
    DashboardScreen(
      onNavigate: _select,
      onIssueBook: () => showIssueLoanDialog(context),
      onAddBook: () => showBookDialog(context),
    ),
    const BooksScreen(),
    const MembersScreen(),
    const LoansScreen(),
    SettingsScreen(themeMode: widget.themeMode),
  ];

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  void _toggleTheme() {
    final Brightness brightness = Theme.of(context).brightness;
    widget.themeMode.value =
        brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final LibraryStore store = LibraryScope.of(context);
    final int overdue = store.overdueLoans;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showRail = constraints.maxWidth >= 780;
        final bool expandedRail = constraints.maxWidth >= 1180;

        final Widget sidebar = _Sidebar(
          index: _index,
          expanded: expandedRail,
          overdue: overdue,
          onSelect: _select,
        );

        final Widget content = Column(
          children: <Widget>[
            _TopBar(
              title: _destinations[_index].label,
              showMenuButton: !showRail,
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onToggleTheme: _toggleTheme,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            Expanded(
              child: IndexedStack(index: _index, children: _screens),
            ),
          ],
        );

        if (showRail) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                SizedBox(
                  width: expandedRail ? 244 : 78,
                  child: sidebar,
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(
            width: 264,
            backgroundColor: context.colors.sidebar,
            child: SafeArea(
              child: _Sidebar(
                index: _index,
                expanded: true,
                overdue: overdue,
                onSelect: (int index) {
                  Navigator.of(context).pop();
                  _select(index);
                },
              ),
            ),
          ),
          body: content,
        );
      },
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.index,
    required this.expanded,
    required this.overdue,
    required this.onSelect,
  });

  final int index;
  final bool expanded;
  final int overdue;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 18 : 0,
                20,
                expanded ? 16 : 0,
                18,
              ),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[Color(0xFF2B6B58), Color(0xFF14453A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFFF3E7CB),
                      size: 19,
                    ),
                  ),
                  if (expanded) ...<Widget>[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Shelfwise',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Library workspace',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colors.muted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 10),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < _AppShellState._destinations.length; i++)
                    _NavTile(
                      key: ValueKey<String>(
                        'nav-${_AppShellState._destinations[i].label.toLowerCase()}',
                      ),
                      destination: _AppShellState._destinations[i],
                      expanded: expanded,
                      selected: index == i,
                      badge: i == 3 && overdue > 0 ? '$overdue' : null,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            const Spacer(),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.infoSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.cloud_off_outlined,
                          size: 17, color: colors.info),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Demo workspace · data lives in this session',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.35,
                            color: colors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 16 : 10,
                8,
                expanded ? 16 : 10,
                18,
              ),
              child: expanded
                  ? Row(
                      children: <Widget>[
                        const InitialsAvatar(initials: 'LO', size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Demo librarian',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Full access',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Tooltip(
                        message: 'Demo librarian',
                        child: InitialsAvatar(initials: 'LO', size: 34),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.destination,
    required this.expanded,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final _NavDestination destination;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);
    final Color foreground =
        selected ? theme.colorScheme.onPrimary : colors.muted;
    final Color background =
        selected ? theme.colorScheme.primary : Colors.transparent;

    final Widget tile = Material(
      color: background,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
          child: Row(
            mainAxisAlignment: expanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 19,
                color: foreground,
              ),
              if (expanded) ...<Widget>[
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                          : colors.dangerSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : colors.danger,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: expanded
          ? tile
          : Tooltip(
              message: badge == null
                  ? destination.label
                  : '${destination.label} · $badge overdue',
              child: tile,
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.showMenuButton,
    required this.onMenu,
    required this.onToggleTheme,
    required this.isDark,
  });

  final String title;
  final bool showMenuButton;
  final VoidCallback onMenu;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 620;
          return Row(
            children: <Widget>[
              if (showMenuButton) ...<Widget>[
                IconButton(
                  tooltip: 'Open navigation',
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded),
                ),
                const SizedBox(width: 4),
              ],
              if (!showMenuButton && !wide) ...<Widget>[
                Icon(Icons.auto_stories_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Text(
                'Library',
                style: TextStyle(fontSize: 12.5, color: colors.muted),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right_rounded,
                    size: 16, color: colors.muted),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (wide)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: colors.muted),
                      const SizedBox(width: 6),
                      Text(
                        formatDate(DateTime.now()),
                        style: TextStyle(fontSize: 11.5, color: colors.muted),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                onPressed: onToggleTheme,
                icon: Icon(
                  isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              const InitialsAvatar(initials: 'LO', size: 32),
              if (wide) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  'Demo librarian',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
