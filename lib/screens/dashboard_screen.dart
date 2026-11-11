import 'package:flutter/material.dart';

import '../data/library_store.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/stat_card.dart';

/// Overview of the collection with quick access to the busiest areas.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onIssueBook,
    required this.onAddBook,
  });

  /// Index of the destination tab in the shell.
  final ValueChanged<int> onNavigate;
  final VoidCallback onIssueBook;
  final VoidCallback onAddBook;

  @override
  Widget build(BuildContext context) {
    final LibraryStore store = LibraryScope.of(context);
    final AppColors colors = context.colors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HeroBanner(
                store: store,
                isDark: isDark,
                onIssueBook: onIssueBook,
                onAddBook: onAddBook,
              ),
              const SizedBox(height: 20),
              _StatGrid(store: store, onNavigate: onNavigate),
              const SizedBox(height: 20),
              _Pair(
                breakpoint: 1000,
                left: _Panel(
                  title: 'Collection activity',
                  caption: 'Books issued over the last six months',
                  trailing: Pill(
                    label: '${store.loans.length} lifetime loans',
                    foreground: Theme.of(context).colorScheme.primary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: ActivityBars(data: store.monthlyLoans),
                  ),
                ),
                right: _Panel(
                  title: 'Genre mix',
                  caption: '${store.totalTitles} titles catalogued',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: GenreBars(distribution: store.genreDistribution),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _Pair(
                breakpoint: 1000,
                left: _Panel(
                  title: 'Recent loans',
                  caption: 'Latest checkouts across the library',
                  trailing: TextButton(
                    onPressed: () => onNavigate(3),
                    child: const Text('View all'),
                  ),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 6),
                      ...store.sortedLoans.take(5).map(
                            (Loan loan) => _RecentLoanRow(
                              loan: loan,
                              store: store,
                              onTap: () => onNavigate(3),
                            ),
                          ),
                      if (store.loans.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No loans yet. Issue the first book from the Loans tab.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                right: Column(
                  children: <Widget>[
                    _Panel(
                      title: 'Needs attention',
                      caption: store.overdueLoans == 0
                          ? 'Everything is on schedule'
                          : '${store.overdueLoans} overdue ${store.overdueLoans == 1 ? 'loan' : 'loans'}',
                      trailing: Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: store.overdueLoans == 0
                            ? colors.success
                            : colors.danger,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: store.overdueLoans == 0
                            ? Row(
                                children: <Widget>[
                                  Icon(Icons.verified_rounded,
                                      size: 20, color: colors.success),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'No overdue books. Nice work keeping the shelves in order.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: colors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: store.overdueLoanList
                                    .take(3)
                                    .map((Loan loan) => _OverdueRow(
                                          loan: loan,
                                          store: store,
                                        ))
                                    .toList(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Panel(
                      title: 'Most borrowed',
                      caption: 'All-time checkout leaders',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: <Widget>[
                            for (int i = 0;
                                i < store.popularBooks.length;
                                i++)
                              _PopularRow(
                                rank: i + 1,
                                title: store.popularBooks[i].key.title,
                                loans: store.popularBooks[i].value,
                              ),
                            if (store.popularBooks.isEmpty)
                              Text(
                                'No checkout history yet.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.store,
    required this.isDark,
    required this.onIssueBook,
    required this.onAddBook,
  });

  final LibraryStore store;
  final bool isDark;
  final VoidCallback onIssueBook;
  final VoidCallback onAddBook;

  @override
  Widget build(BuildContext context) {
    final double utilisation = store.utilisation;
    final List<Color> gradient = isDark
        ? const <Color>[Color(0xFF2B6B58), Color(0xFF163A30)]
        : const <Color>[Color(0xFF1F5A4A), Color(0xFF14392F)];

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 24, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;
          final Widget copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  formatLongDate(DateTime.now()),
                  style: const TextStyle(
                    color: Color(0xFFEAF3EE),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${greetingForHour(DateTime.now().hour)}, Librarian',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${store.availableCopies} of ${store.totalCopies} copies are on '
                'the shelf today. ${store.overdueLoans} loans need a nudge.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onIssueBook,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE9D5A9),
                      foregroundColor: const Color(0xFF2A2416),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Issue a book'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddBook,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add a title'),
                  ),
                ],
              ),
            ],
          );

          if (compact) return copy;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: copy),
              const SizedBox(width: 24),
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: utilisation),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (BuildContext context, double value, Widget? _) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 9,
                            backgroundColor: Colors.white.withValues(alpha: 0.16),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE9D5A9),
                            ),
                            strokeCap: StrokeCap.round,
                          );
                        },
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${(utilisation * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          'on loan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.store, required this.onNavigate});

  final LibraryStore store;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1080
            ? 4
            : constraints.maxWidth >= 640
                ? 2
                : 1;
        const double gap = 16;
        final double width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        final List<Widget> cards = <Widget>[
          StatCard(
            label: 'Titles catalogued',
            value: '${store.totalTitles}',
            caption:
                '${store.totalCopies} copies across ${store.genres.length} genres',
            icon: Icons.menu_book_rounded,
            accent: Theme.of(context).colorScheme.primary,
            accentSoft: colors.infoSoft,
            onTap: () => onNavigate(1),
          ),
          StatCard(
            label: 'Copies on loan',
            value: '${store.onLoanCopies}',
            caption:
                '${(store.utilisation * 100).round()}% of the collection is out',
            icon: Icons.swap_horiz_rounded,
            accent: colors.info,
            accentSoft: colors.infoSoft,
            onTap: () => onNavigate(3),
          ),
          StatCard(
            label: 'Active members',
            value: '${store.activeMembers}',
            caption:
                '${store.members.length} registered · ${store.activeLoans} books held',
            icon: Icons.people_alt_rounded,
            accent: colors.success,
            accentSoft: colors.successSoft,
            onTap: () => onNavigate(2),
          ),
          StatCard(
            label: 'Overdue loans',
            value: '${store.overdueLoans}',
            caption: store.overdueLoans == 0
                ? 'Nothing past its due date'
                : 'Follow up with members this week',
            icon: Icons.schedule_rounded,
            accent: store.overdueLoans == 0 ? colors.success : colors.danger,
            accentSoft: store.overdueLoans == 0
                ? colors.successSoft
                : colors.dangerSoft,
            onTap: () => onNavigate(3),
          ),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((Widget card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

/// Two cards side by side on wide screens, stacked otherwise.
class _Pair extends StatelessWidget {
  const _Pair({
    required this.left,
    required this.right,
    this.breakpoint = 900,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              left,
              const SizedBox(height: 20),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 3, child: left),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: right),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.caption,
    required this.child,
    this.trailing,
  });

  final String title;
  final String caption;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionTitle(title: title, caption: caption, trailing: trailing),
          child,
        ],
      ),
    );
  }
}

class _RecentLoanRow extends StatelessWidget {
  const _RecentLoanRow({
    required this.loan,
    required this.store,
    required this.onTap,
  });

  final Loan loan;
  final LibraryStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String title = store.bookById(loan.bookId)?.title ?? 'Removed title';
    final String member =
        store.memberById(loan.memberId)?.name ?? 'Removed member';
    final bool overdue = loan.isOverdue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: overdue ? colors.dangerSoft : colors.infoSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                overdue ? Icons.schedule_rounded : Icons.book_rounded,
                size: 16,
                color: overdue ? colors.danger : colors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$member · ${formatShortDate(loan.issuedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pill(
              label: loan.isReturned
                  ? 'Returned'
                  : overdue
                      ? '${loan.overdueDays}d late'
                      : formatRelativeDay(loan.dueDate),
              dense: true,
              foreground: loan.isReturned
                  ? colors.muted
                  : overdue
                      ? colors.danger
                      : colors.success,
              background: loan.isReturned
                  ? colors.border.withValues(alpha: 0.4)
                  : overdue
                      ? colors.dangerSoft
                      : colors.successSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueRow extends StatelessWidget {
  const _OverdueRow({required this.loan, required this.store});

  final Loan loan;
  final LibraryStore store;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String title = store.bookById(loan.bookId)?.title ?? 'Removed title';
    final String member =
        store.memberById(loan.memberId)?.name ?? 'Removed member';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 17, color: colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$member · ${loan.overdueDays} ${loan.overdueDays == 1 ? 'day' : 'days'} late',
                  style: TextStyle(fontSize: 11, color: colors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({
    required this.rank,
    required this.title,
    required this.loans,
  });

  final int rank;
  final String title;
  final int loans;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Pill(label: '$loans×', dense: true),
        ],
      ),
    );
  }
}
