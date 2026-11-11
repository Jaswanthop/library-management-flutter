import 'package:flutter/material.dart';

import '../data/library_store.dart';
import '../dialogs/loan_dialog.dart';
import '../models/book.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

enum _LoanFilter { all, active, overdue, returned }

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final TextEditingController _search = TextEditingController();
  _LoanFilter _filter = _LoanFilter.active;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _issue() async {
    final bool created = await showIssueLoanDialog(context);
    if (created && mounted) showToast(context, 'Book issued successfully.');
  }

  void _return(Loan loan) {
    try {
      LibraryScope.read(context).returnLoan(loan.id);
      final String title =
          LibraryScope.read(context).bookById(loan.bookId)?.title ??
              'The book';
      showToast(context, '“$title” is back on the shelf.');
    } on LibraryException catch (error) {
      showToast(context, error.message, error: true);
    }
  }

  void _renew(Loan loan) {
    try {
      LibraryScope.read(context).renewLoan(loan.id, days: 7);
      showToast(context, 'Loan extended by 7 days.');
    } on LibraryException catch (error) {
      showToast(context, error.message, error: true);
    }
  }

  List<Loan> _visibleLoans(LibraryStore store) {
    final String query = _search.text.trim().toLowerCase();
    return store.sortedLoans.where((Loan loan) {
      final Book? book = store.bookById(loan.bookId);
      final Member? member = store.memberById(loan.memberId);
      final bool matchesQuery = query.isEmpty ||
          (book?.title.toLowerCase().contains(query) ?? false) ||
          (book?.author.toLowerCase().contains(query) ?? false) ||
          (member?.name.toLowerCase().contains(query) ?? false) ||
          (member?.email.toLowerCase().contains(query) ?? false) ||
          loan.id.toLowerCase().contains(query);
      final bool matchesFilter = switch (_filter) {
        _LoanFilter.all => true,
        _LoanFilter.active => loan.isActive,
        _LoanFilter.overdue => loan.isOverdue,
        _LoanFilter.returned => loan.isReturned,
      };
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((Loan a, Loan b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.dueDate.compareTo(b.dueDate);
      });
  }

  @override
  Widget build(BuildContext context) {
    final LibraryStore store = LibraryScope.of(context);
    final AppColors colors = context.colors;
    final List<Loan> visible = _visibleLoans(store);

    final Map<_LoanFilter, int> counts = <_LoanFilter, int>{
      _LoanFilter.all: store.loans.length,
      _LoanFilter.active: store.activeLoans,
      _LoanFilter.overdue: store.overdueLoans,
      _LoanFilter.returned:
          store.loans.where((Loan loan) => loan.isReturned).length,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PageHeader(
                title: 'Loans',
                subtitle:
                    '${store.activeLoans} books out · ${store.overdueLoans} overdue '
                    '· ${counts[_LoanFilter.returned]} returned',
                actions: <Widget>[
                  FilledButton.icon(
                    onPressed: _issue,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Issue a book'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search by book, member or loan ID',
                              hintStyle: TextStyle(
                                  fontSize: 13.5, color: colors.muted),
                              prefixIcon: Icon(Icons.search_rounded,
                                  size: 20, color: colors.muted),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        _search.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18),
                                    ),
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _LoanFilter.values.map((_LoanFilter filter) {
                          final bool selected = _filter == filter;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = filter),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '${switch (filter) {
                                _LoanFilter.all => 'All',
                                _LoanFilter.active => 'On loan',
                                _LoanFilter.overdue => 'Overdue',
                                _LoanFilter.returned => 'Returned',
                              }} (${counts[filter]})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : colors.muted,
                              ),
                            ),
                            selectedColor: Theme.of(context).colorScheme.primary,
                            backgroundColor: colors.border.withValues(alpha: 0.25),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                AppCard(
                  child: EmptyState(
                    icon: Icons.swap_horiz_rounded,
                    title: store.loans.isEmpty
                        ? 'No loans recorded yet'
                        : 'Nothing to show here',
                    message: store.loans.isEmpty
                        ? 'Issue a book to a member and the loan will appear here '
                            'with its due date.'
                        : 'Try a different filter or clear the search.',
                    action: store.loans.isEmpty
                        ? FilledButton.icon(
                            onPressed: _issue,
                            icon: const Icon(Icons.swap_horiz_rounded,
                                size: 18),
                            label: const Text('Issue the first book'),
                          )
                        : null,
                  ),
                )
              else
                Column(
                  children: <Widget>[
                    for (final Loan loan in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LoanRow(
                          loan: loan,
                          store: store,
                          onReturn: () => _return(loan),
                          onRenew: () => _renew(loan),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({
    required this.loan,
    required this.store,
    required this.onReturn,
    required this.onRenew,
  });

  final Loan loan;
  final LibraryStore store;
  final VoidCallback onReturn;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Book? book = store.bookById(loan.bookId);
    final Member? member = store.memberById(loan.memberId);
    final bool overdue = loan.isOverdue;

    final Color statusColor = loan.isReturned
        ? colors.muted
        : overdue
            ? colors.danger
            : colors.success;
    final Color statusSoft = loan.isReturned
        ? colors.border.withValues(alpha: 0.35)
        : overdue
            ? colors.dangerSoft
            : colors.successSoft;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool showDates = constraints.maxWidth >= 780;
          final bool showMember = constraints.maxWidth >= 560;
          return Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  loan.isReturned
                      ? Icons.check_circle_outline_rounded
                      : overdue
                          ? Icons.schedule_rounded
                          : Icons.book_rounded,
                  size: 19,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book?.title ?? 'Removed title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book == null
                          ? loan.id
                          : '${book.author} · ${loan.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: colors.muted),
                    ),
                  ],
                ),
              ),
              if (showMember)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: <Widget>[
                      InitialsAvatar(
                        initials: initialsOf(member?.name ?? '?'),
                        size: 28,
                        seed: (member?.name ?? '?')
                            .codeUnits
                            .fold<int>(0, (int a, int b) => a + b),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              member?.name ?? 'Removed member',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              member?.tier.label ?? '—',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (showDates) ...<Widget>[
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'ISSUED',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatShortDate(loan.issuedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 108,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        loan.isReturned ? 'RETURNED' : 'DUE',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatShortDate(
                          loan.returnedAt ?? loan.dueDate,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: overdue ? colors.danger : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Pill(
                label: loan.isReturned
                    ? 'Returned'
                    : overdue
                        ? '${loan.overdueDays}d late'
                        : '${daysUntil(loan.dueDate)}d left',
                foreground: statusColor,
                background: statusSoft,
              ),
              const SizedBox(width: 6),
              if (!loan.isReturned)
                PopupMenuButton<String>(
                  tooltip: 'Loan actions',
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: colors.muted),
                  onSelected: (String value) {
                    switch (value) {
                      case 'return':
                        onReturn();
                        break;
                      case 'renew':
                        onRenew();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'return',
                      child: Text('Mark as returned'),
                    ),
                    PopupMenuItem<String>(
                      value: 'renew',
                      child: Text('Renew for 7 days'),
                    ),
                  ],
                )
              else
                const SizedBox(width: 40),
            ],
          );
        },
      ),
    );
  }
}
