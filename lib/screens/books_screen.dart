import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/library_store.dart';
import '../dialogs/book_dialog.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/loan_dialog.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../utils/feedback.dart';
import '../widgets/common.dart';

enum _Availability { all, available, onLoan }

enum _BookSort { recent, title, author, copies }

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _search = TextEditingController();
  String _genre = 'All genres';
  _Availability _availability = _Availability.all;
  _BookSort _sort = _BookSort.recent;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Book> _visibleBooks(LibraryStore store) {
    final String query = _search.text.trim().toLowerCase();
    final List<Book> filtered = store.books.where((Book book) {
      final bool matchesQuery = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.isbn.toLowerCase().contains(query) ||
          book.genre.toLowerCase().contains(query);
      final bool matchesGenre =
          _genre == 'All genres' || book.genre == _genre;
      final bool matchesAvailability = switch (_availability) {
        _Availability.all => true,
        _Availability.available => book.availableCopies > 0,
        _Availability.onLoan => book.onLoanCopies > 0,
      };
      return matchesQuery && matchesGenre && matchesAvailability;
    }).toList();

    switch (_sort) {
      case _BookSort.recent:
        filtered.sort((Book a, Book b) => b.addedAt.compareTo(a.addedAt));
        break;
      case _BookSort.title:
        filtered.sort((Book a, Book b) => a.title.compareTo(b.title));
        break;
      case _BookSort.author:
        filtered.sort((Book a, Book b) => a.author.compareTo(b.author));
        break;
      case _BookSort.copies:
        filtered.sort((Book a, Book b) => b.totalCopies.compareTo(a.totalCopies));
        break;
    }
    return filtered;
  }

  Future<void> _addBook() async {
    final bool saved = await showBookDialog(context);
    if (saved && mounted) showToast(context, 'Book added to the catalogue.');
  }

  Future<void> _editBook(Book book) async {
    final bool saved = await showBookDialog(context, book: book);
    if (saved && mounted) showToast(context, '“${book.title}” updated.');
  }

  Future<void> _issueBook(Book book) async {
    final bool created = await showIssueLoanDialog(context, bookId: book.id);
    if (created && mounted) {
      showToast(context, '“${book.title}” is checked out.');
    }
  }

  Future<void> _deleteBook(Book book) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Delete “${book.title}”?',
      message:
          'This removes the title and its loan history from the catalogue. '
          'This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    try {
      LibraryScope.read(context).deleteBook(book.id);
      if (mounted) showToast(context, '“${book.title}” removed.');
    } on LibraryException catch (error) {
      if (mounted) showToast(context, error.message, error: true);
    }
  }

  Future<void> _exportCsv() async {
    final LibraryStore store = LibraryScope.read(context);
    await Clipboard.setData(ClipboardData(text: store.booksAsCsv()));
    if (mounted) {
      showToast(context, 'Catalogue copied to the clipboard as CSV.',
          icon: Icons.file_download_done_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LibraryStore store = LibraryScope.of(context);
    final AppColors colors = context.colors;
    final List<Book> visible = _visibleBooks(store);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PageHeader(
                title: 'Catalogue',
                subtitle:
                    '${store.totalTitles} titles · ${store.totalCopies} copies · '
                    '${store.availableCopies} on the shelf',
                actions: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _exportCsv,
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: const Text('Export CSV'),
                  ),
                  FilledButton.icon(
                    onPressed: _addBook,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add book'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool wide = constraints.maxWidth >= 760;
                    final Widget search = TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by title, author, ISBN or genre',
                        hintStyle:
                            TextStyle(fontSize: 13.5, color: colors.muted),
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
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                    final Widget genre = _CompactSelect<String>(
                      icon: Icons.local_library_outlined,
                      value: _genre,
                      items: <String>['All genres', ...store.genres],
                      onChanged: (String value) =>
                          setState(() => _genre = value),
                    );
                    final Widget availability = _CompactSelect<_Availability>(
                      icon: Icons.tune_rounded,
                      value: _availability,
                      items: _Availability.values,
                      labelOf: (_Availability value) => switch (value) {
                        _Availability.all => 'All copies',
                        _Availability.available => 'On the shelf',
                        _Availability.onLoan => 'On loan',
                      },
                      onChanged: (_Availability value) =>
                          setState(() => _availability = value),
                    );
                    final Widget sort = _CompactSelect<_BookSort>(
                      icon: Icons.sort_rounded,
                      value: _sort,
                      items: _BookSort.values,
                      labelOf: (_BookSort value) => switch (value) {
                        _BookSort.recent => 'Newest first',
                        _BookSort.title => 'Title A–Z',
                        _BookSort.author => 'Author A–Z',
                        _BookSort.copies => 'Most copies',
                      },
                      onChanged: (_BookSort value) =>
                          setState(() => _sort = value),
                    );

                    if (!wide) {
                      return Column(
                        children: <Widget>[
                          search,
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[genre, availability, sort],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: <Widget>[
                        Expanded(child: search),
                        const SizedBox(width: 10),
                        genre,
                        const SizedBox(width: 8),
                        availability,
                        const SizedBox(width: 8),
                        sort,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Text(
                    '${visible.length} ${visible.length == 1 ? 'title' : 'titles'}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.muted,
                    ),
                  ),
                  const Spacer(),
                  if (_search.text.isNotEmpty ||
                      _genre != 'All genres' ||
                      _availability != _Availability.all)
                    TextButton.icon(
                      onPressed: () {
                        _search.clear();
                        setState(() {
                          _genre = 'All genres';
                          _availability = _Availability.all;
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                      label: const Text('Reset filters'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (store.books.isEmpty)
                AppCard(
                  child: EmptyState(
                    icon: Icons.library_add_outlined,
                    title: 'Your catalogue is empty',
                    message:
                        'Add the first title to start tracking copies, members '
                        'and loans.',
                    action: FilledButton.icon(
                      onPressed: _addBook,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add the first book'),
                    ),
                  ),
                )
              else if (visible.isEmpty)
                AppCard(child: const NoResults(message: 'No books match these filters.'))
              else
                Column(
                  children: <Widget>[
                    for (final Book book in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BookRow(
                          book: book,
                          onIssue: () => _issueBook(book),
                          onEdit: () => _editBook(book),
                          onDelete: () => _deleteBook(book),
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

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.onIssue,
    required this.onEdit,
    required this.onDelete,
  });

  final Book book;
  final VoidCallback onIssue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool showCopies = constraints.maxWidth >= 720;
          final bool showIssueButton = constraints.maxWidth >= 560;
          return Row(
            children: <Widget>[
              _Cover(book: book),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: colors.muted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        Pill(
                          label: book.genre,
                          dense: true,
                          foreground: Theme.of(context).colorScheme.primary,
                          background: colors.infoSoft,
                        ),
                        Pill(
                          label: 'Shelf ${book.shelf}',
                          dense: true,
                          icon: Icons.shelves,
                        ),
                        Pill(label: '${book.year}', dense: true),
                        if (book.isAvailable)
                          Pill(
                            label: 'Available',
                            dense: true,
                            foreground: colors.success,
                            background: colors.successSoft,
                          )
                        else
                          Pill(
                            label: 'All copies out',
                            dense: true,
                            foreground: colors.danger,
                            background: colors.dangerSoft,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showCopies) ...<Widget>[
                const SizedBox(width: 16),
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${book.availableCopies} of ${book.totalCopies}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: book.totalCopies == 0
                              ? 0
                              : book.availableCopies / book.totalCopies,
                          minHeight: 5,
                          backgroundColor: colors.border.withValues(alpha: 0.6),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            book.isAvailable ? colors.success : colors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'on the shelf',
                        style:
                            TextStyle(fontSize: 10.5, color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 8),
              if (showIssueButton)
                TextButton.icon(
                  onPressed: book.isAvailable ? onIssue : null,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Issue'),
                ),
              PopupMenuButton<String>(
                tooltip: 'Book actions',
                icon: Icon(Icons.more_vert_rounded, color: colors.muted),
                onSelected: (String value) {
                  switch (value) {
                    case 'issue':
                      onIssue();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'issue',
                    child: _MenuRow(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Issue copy',
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: _MenuRow(
                      icon: Icons.edit_outlined,
                      label: 'Edit details',
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: _MenuRow(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete title',
                      color: colors.danger,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: <Color>[
            book.coverColor,
            Color.lerp(book.coverColor, Colors.black, 0.28)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Center(
            child: Text(
              book.title.isEmpty ? '?' : book.title[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13.5, color: color),
        ),
      ],
    );
  }
}

/// Compact dropdown used in toolbars.
class _CompactSelect<T> extends StatelessWidget {
  const _CompactSelect({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelOf,
  });

  final IconData icon;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelOf;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.muted),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: colors.muted),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              items: items
                  .map((T item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(labelOf?.call(item) ?? '$item'),
                      ))
                  .toList(),
              onChanged: (T? selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ],
      ),
    );
  }
}
