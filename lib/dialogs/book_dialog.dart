import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/library_store.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/fields.dart';

/// Adds a new title, or edits [book] when provided.
Future<bool> showBookDialog(BuildContext context, {Book? book}) async {
  final bool? saved = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => _BookFormDialog(book: book),
  );
  return saved ?? false;
}

class _BookFormDialog extends StatefulWidget {
  const _BookFormDialog({this.book});

  final Book? book;

  @override
  State<_BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<_BookFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _isbn;
  late final TextEditingController _genre;
  late final TextEditingController _year;
  late final TextEditingController _shelf;
  late int _copies;

  bool get _isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final Book? book = widget.book;
    _title = TextEditingController(text: book?.title ?? '');
    _author = TextEditingController(text: book?.author ?? '');
    _isbn = TextEditingController(text: book?.isbn ?? '');
    _genre = TextEditingController(text: book?.genre ?? '');
    _year = TextEditingController(
      text: '${book?.year ?? DateTime.now().year}',
    );
    _shelf = TextEditingController(text: book?.shelf ?? '');
    _copies = book?.totalCopies ?? 1;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _isbn.dispose();
    _genre.dispose();
    _year.dispose();
    _shelf.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final LibraryStore store = LibraryScope.read(context);
    final int year = int.tryParse(_year.text.trim()) ?? DateTime.now().year;
    try {
      if (_isEditing) {
        store.updateBook(
          id: widget.book!.id,
          title: _title.text,
          author: _author.text,
          isbn: _isbn.text,
          genre: _genre.text,
          year: year,
          copies: _copies,
          shelf: _shelf.text,
        );
      } else {
        store.addBook(
          title: _title.text,
          author: _author.text,
          isbn: _isbn.text,
          genre: _genre.text,
          year: year,
          copies: _copies,
          shelf: _shelf.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on LibraryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final List<String> genres = LibraryScope.read(context).genres;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
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
                      color: context.colors.infoSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.edit_note_rounded
                          : Icons.menu_book_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _isEditing ? 'Edit book' : 'Add a book',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditing
                              ? 'Update the catalogue details for this title.'
                              : 'New titles become available to borrow straight away.',
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
                      AppTextField(
                        controller: _title,
                        label: 'Title *',
                        hint: 'The Name of the Wind',
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            (value ?? '').trim().isEmpty
                                ? 'A title is required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _author,
                        label: 'Author *',
                        hint: 'Patrick Rothfuss',
                        textInputAction: TextInputAction.next,
                        validator: (String? value) =>
                            (value ?? '').trim().isEmpty
                                ? 'An author is required'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints c) {
                          final bool twoColumns = c.maxWidth >= 480;
                          final Widget isbnField = AppTextField(
                            controller: _isbn,
                            label: 'ISBN',
                            hint: '978-0756404741',
                            textInputAction: TextInputAction.next,
                          );
                          final Widget yearField = AppTextField(
                            controller: _year,
                            label: 'Published',
                            hint: '2007',
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (String? value) {
                              final int? year = int.tryParse(
                                (value ?? '').trim(),
                              );
                              if (year == null) return 'Enter a year';
                              if (year < 1000 ||
                                  year > DateTime.now().year + 1) {
                                return 'Check the year';
                              }
                              return null;
                            },
                          );
                          if (!twoColumns) {
                            return Column(
                              children: <Widget>[
                                isbnField,
                                const SizedBox(height: 14),
                                yearField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(flex: 3, child: isbnField),
                              const SizedBox(width: 14),
                              Expanded(flex: 2, child: yearField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _genre,
                        label: 'Genre',
                        hint: genres.isEmpty
                            ? 'Fantasy'
                            : 'e.g. ${genres.take(2).join(', ')}',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: AppTextField(
                              controller: _shelf,
                              label: 'Shelf',
                              hint: 'A-12',
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 14),
                          NumberStepper(
                            label: 'Copies',
                            value: _copies,
                            min: widget.book?.onLoanCopies ?? 1,
                            max: 99,
                            onChanged: (int value) =>
                                setState(() => _copies = value),
                          ),
                        ],
                      ),
                      if (_isEditing && widget.book!.onLoanCopies > 0) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          '${widget.book!.onLoanCopies} of ${widget.book!.totalCopies} copies are currently on loan.',
                          style: TextStyle(fontSize: 12, color: colors.muted),
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
                    onPressed: _submit,
                    icon: Icon(
                      _isEditing
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(_isEditing ? 'Save changes' : 'Add book'),
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
