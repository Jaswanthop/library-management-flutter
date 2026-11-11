import 'package:flutter/material.dart';

import '../data/library_store.dart';
import '../models/book.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/fields.dart';

/// Issues a copy of a book to a member.
Future<bool> showIssueLoanDialog(
  BuildContext context, {
  String? bookId,
  String? memberId,
}) async {
  final bool? created = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => _IssueLoanDialog(
      initialBookId: bookId,
      initialMemberId: memberId,
    ),
  );
  return created ?? false;
}

class _IssueLoanDialog extends StatefulWidget {
  const _IssueLoanDialog({this.initialBookId, this.initialMemberId});

  final String? initialBookId;
  final String? initialMemberId;

  @override
  State<_IssueLoanDialog> createState() => _IssueLoanDialogState();
}

class _IssueLoanDialogState extends State<_IssueLoanDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _bookId;
  String? _memberId;
  int _days = 14;
  String? _error;

  @override
  void initState() {
    super.initState();
    final LibraryStore store = LibraryScope.read(context);
    final List<Book> available = store.books
        .where((Book book) => book.availableCopies > 0)
        .toList();
    _bookId = widget.initialBookId ??
        (available.isNotEmpty ? available.first.id : null);
    final List<Member> activeMembers =
        store.members.where((Member member) => member.isActive).toList();
    _memberId = widget.initialMemberId ??
        (activeMembers.isNotEmpty ? activeMembers.first.id : null);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_bookId == null || _memberId == null) {
      setState(() => _error = 'Choose both a book and a member.');
      return;
    }
    final LibraryStore store = LibraryScope.read(context);
    try {
      store.issueLoan(bookId: _bookId!, memberId: _memberId!, days: _days);
      if (mounted) Navigator.of(context).pop(true);
    } on LibraryException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LibraryStore store = LibraryScope.of(context);
    final AppColors colors = context.colors;

    final List<Book> availableBooks = store.books
        .where((Book book) => book.availableCopies > 0)
        .toList()
      ..sort((Book a, Book b) => a.title.compareTo(b.title));
    final List<Member> activeMembers = store.members
        .where((Member member) => member.isActive)
        .toList()
      ..sort((Member a, Member b) => a.name.compareTo(b.name));

    final Book? selectedBook = _bookId == null ? null : store.bookById(_bookId!);
    final Member? selectedMember =
        _memberId == null ? null : store.memberById(_memberId!);

    final bool canSubmit = availableBooks.isNotEmpty && activeMembers.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 0),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.successSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: colors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Issue a book',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Check out a copy against a member record.',
                          style: TextStyle(fontSize: 12.5, color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppDropdown<String>(
                        label: 'Book',
                        value: _bookId,
                        hint: 'Select an available title',
                        items: availableBooks
                            .map((Book book) => DropdownMenuItem<String>(
                                  value: book.id,
                                  child: Text(
                                    '${book.title} · ${book.availableCopies} '
                                    'available',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (String? value) =>
                            setState(() {
                          _bookId = value;
                          _error = null;
                        }),
                        validator: (String? value) =>
                            value == null ? 'Choose a book' : null,
                      ),
                      if (selectedBook != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          'by ${selectedBook.author} · shelf ${selectedBook.shelf}',
                          style: TextStyle(fontSize: 11.5, color: colors.muted),
                        ),
                      ],
                      const SizedBox(height: 14),
                      AppDropdown<String>(
                        label: 'Member',
                        value: _memberId,
                        hint: 'Select a member',
                        items: activeMembers.map((Member member) {
                          final int held =
                              store.activeLoanCountForMember(member.id);
                          return DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(
                              '${member.name} · $held/${member.loanLimit} held',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) =>
                            setState(() {
                          _memberId = value;
                          _error = null;
                        }),
                        validator: (String? value) =>
                            value == null ? 'Choose a member' : null,
                      ),
                      if (selectedMember != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          '${selectedMember.tier.label} member · '
                          '${selectedMember.email}',
                          style: TextStyle(fontSize: 11.5, color: colors.muted),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Loan period',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <int>[7, 14, 21, 28].map((int days) {
                          final bool selected = _days == days;
                          return ChoiceChip(
                            label: Text('$days days'),
                            selected: selected,
                            onSelected: (_) => setState(() => _days = days),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.infoSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.event_available_rounded,
                                size: 18, color: colors.info),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Due back by ${formatLongDate(todayPlus(_days))} '
                                '(${formatRelativeDay(todayPlus(_days))}).',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: colors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.dangerSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.error_outline_rounded,
                                  size: 17, color: colors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!canSubmit) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          availableBooks.isEmpty
                              ? 'Every copy is currently on loan. Add copies to the title first.'
                              : 'There are no active members to lend to.',
                          style: TextStyle(fontSize: 12, color: colors.danger),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Issue book'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
