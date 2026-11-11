import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../utils/formatters.dart';
import 'seed_data.dart';

/// Thrown when an action would break a library rule (e.g. lending a copy that
/// is not on the shelf). The message is written for end users.
class LibraryException implements Exception {
  LibraryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// In-memory source of truth for the whole app. Widgets listen through
/// [LibraryScope] and rebuild when [notifyListeners] fires.
class LibraryStore extends ChangeNotifier {
  LibraryStore({
    List<Book> books = const <Book>[],
    List<Member> members = const <Member>[],
    List<Loan> loans = const <Loan>[],
  })  : _books = List<Book>.of(books),
        _members = List<Member>.of(members),
        _loans = List<Loan>.of(loans);

  /// Builds a store pre-filled with a demo catalogue.
  factory LibraryStore.seeded() {
    final LibrarySeed seed = buildSeed();
    return LibraryStore(
      books: seed.books,
      members: seed.members,
      loans: seed.loans,
    );
  }

  final List<Book> _books;
  final List<Member> _members;
  final List<Loan> _loans;
  int _idCounter = 1000;

  List<Book> get books => List<Book>.unmodifiable(_books);
  List<Member> get members => List<Member>.unmodifiable(_members);
  List<Loan> get loans => List<Loan>.unmodifiable(_loans);

  List<String> get genres {
    final Set<String> unique =
        _books.map((Book book) => book.genre).toSet();
    final List<String> sorted = unique.toList()..sort();
    return sorted;
  }

  Book? bookById(String id) {
    for (final Book book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Member? memberById(String id) {
    for (final Member member in _members) {
      if (member.id == id) return member;
    }
    return null;
  }

  Loan? activeLoanForBook(String bookId) {
    for (final Loan loan in _loans) {
      if (loan.bookId == bookId && loan.isActive) return loan;
    }
    return null;
  }

  int activeLoanCountForMember(String memberId) {
    return _loans
        .where((Loan loan) => loan.memberId == memberId && loan.isActive)
        .length;
  }

  // ---------------------------------------------------------------------------
  // Aggregates used by the dashboard.
  // ---------------------------------------------------------------------------

  int get totalTitles => _books.length;

  int get totalCopies =>
      _books.fold(0, (int sum, Book book) => sum + book.totalCopies);

  int get availableCopies =>
      _books.fold(0, (int sum, Book book) => sum + book.availableCopies);

  int get onLoanCopies => totalCopies - availableCopies;

  int get activeMembers =>
      _members.where((Member member) => member.isActive).length;

  int get activeLoans =>
      _loans.where((Loan loan) => loan.isActive).length;

  int get overdueLoans =>
      _loans.where((Loan loan) => loan.isOverdue).length;

  double get utilisation =>
      totalCopies == 0 ? 0 : onLoanCopies / totalCopies;

  List<Loan> get overdueLoanList => _loans
      .where((Loan loan) => loan.isOverdue)
      .toList()
    ..sort((Loan a, Loan b) => a.dueDate.compareTo(b.dueDate));

  List<Loan> get activeLoanList => _loans
      .where((Loan loan) => loan.isActive)
      .toList()
    ..sort((Loan a, Loan b) => a.dueDate.compareTo(b.dueDate));

  List<Loan> get sortedLoans => List<Loan>.of(_loans)
    ..sort((Loan a, Loan b) => b.issuedAt.compareTo(a.issuedAt));

  /// Title count per genre, largest first.
  Map<String, int> get genreDistribution {
    final Map<String, int> counts = <String, int>{};
    for (final Book book in _books) {
      counts.update(book.genre, (int value) => value + 1, ifAbsent: () => 1);
    }
    final List<MapEntry<String, int>> entries = counts.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        final int byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return <String, int>{
      for (final MapEntry<String, int> entry in entries)
        entry.key: entry.value,
    };
  }

  /// Loans issued in each of the last six months, oldest first.
  List<MapEntry<DateTime, int>> get monthlyLoans {
    final DateTime now = DateTime.now();
    return List<MapEntry<DateTime, int>>.generate(6, (int index) {
      final int monthsAgo = 5 - index;
      final DateTime month =
          DateTime(now.year, now.month - monthsAgo, 1);
      final int count = _loans.where((Loan loan) {
        return loan.issuedAt.year == month.year &&
            loan.issuedAt.month == month.month;
      }).length;
      return MapEntry<DateTime, int>(month, count);
    });
  }

  /// Books with the most all-time loans.
  List<MapEntry<Book, int>> get popularBooks {
    final Map<String, int> counts = <String, int>{};
    for (final Loan loan in _loans) {
      counts.update(loan.bookId, (int value) => value + 1, ifAbsent: () => 1);
    }
    final List<MapEntry<Book, int>> entries = <MapEntry<Book, int>>[];
    counts.forEach((String bookId, int count) {
      final Book? book = bookById(bookId);
      if (book != null) entries.add(MapEntry<Book, int>(book, count));
    });
    entries.sort((MapEntry<Book, int> a, MapEntry<Book, int> b) {
      return b.value.compareTo(a.value);
    });
    return entries.take(4).toList();
  }

  // ---------------------------------------------------------------------------
  // Books.
  // ---------------------------------------------------------------------------

  Book addBook({
    required String title,
    required String author,
    required String isbn,
    required String genre,
    required int year,
    required int copies,
    required String shelf,
  }) {
    final String cleanTitle = title.trim();
    final String cleanAuthor = author.trim();
    final String cleanIsbn = isbn.trim();
    final String cleanGenre = genre.trim();
    final String cleanShelf = shelf.trim();

    if (cleanTitle.isEmpty) {
      throw LibraryException('A book needs a title.');
    }
    if (cleanAuthor.isEmpty) {
      throw LibraryException('A book needs an author.');
    }
    if (copies < 1) {
      throw LibraryException('Add at least one copy.');
    }
    if (cleanIsbn.isNotEmpty && _isbnExists(cleanIsbn)) {
      throw LibraryException('Another title already uses this ISBN.');
    }

    _idCounter += 1;
    final Book book = Book(
      id: 'B-${_idCounter + 2000}',
      title: cleanTitle,
      author: cleanAuthor,
      isbn: cleanIsbn,
      genre: cleanGenre.isEmpty ? 'General' : cleanGenre,
      year: year,
      totalCopies: copies,
      availableCopies: copies,
      shelf: cleanShelf.isEmpty ? 'Unfiled' : cleanShelf,
      addedAt: DateTime.now(),
      coverColor: _colorForGenre(cleanGenre),
    );
    _books.insert(0, book);
    notifyListeners();
    return book;
  }

  void updateBook({
    required String id,
    required String title,
    required String author,
    required String isbn,
    required String genre,
    required int year,
    required int copies,
    required String shelf,
  }) {
    final int index = _books.indexWhere((Book book) => book.id == id);
    if (index == -1) {
      throw LibraryException('This book could not be found.');
    }
    final Book current = _books[index];
    final String cleanIsbn = isbn.trim();
    if (cleanIsbn.isNotEmpty && _isbnExists(cleanIsbn, ignoreId: id)) {
      throw LibraryException('Another title already uses this ISBN.');
    }
    if (copies < current.onLoanCopies) {
      throw LibraryException(
        '${current.onLoanCopies} copies are on loan — keep at least that many.',
      );
    }
    _books[index] = current.copyWith(
      title: title.trim(),
      author: author.trim(),
      isbn: cleanIsbn,
      genre: genre.trim().isEmpty ? 'General' : genre.trim(),
      year: year,
      totalCopies: copies,
      availableCopies: copies - current.onLoanCopies,
      shelf: shelf.trim().isEmpty ? 'Unfiled' : shelf.trim(),
    );
    notifyListeners();
  }

  void deleteBook(String id) {
    final Book? book = bookById(id);
    if (book == null) {
      throw LibraryException('This book could not be found.');
    }
    if (book.onLoanCopies > 0) {
      throw LibraryException(
        '“${book.title}” has copies on loan and cannot be deleted yet.',
      );
    }
    _books.removeWhere((Book item) => item.id == id);
    _loans.removeWhere((Loan loan) => loan.bookId == id);
    notifyListeners();
  }

  bool _isbnExists(String isbn, {String? ignoreId}) {
    final String needle = isbn.replaceAll('-', '').toLowerCase();
    return _books.any((Book book) {
      if (book.id == ignoreId) return false;
      return book.isbn.replaceAll('-', '').toLowerCase() == needle;
    });
  }

  static Color _colorForGenre(String genre) {
    const List<Color> palette = <Color>[
      Color(0xFF1F5A4A),
      Color(0xFF2B4C7E),
      Color(0xFF7A3E48),
      Color(0xFF8A5A22),
      Color(0xFF3F4E8C),
      Color(0xFF5C3D6E),
      Color(0xFF2D6A6A),
      Color(0xFF7B4B2A),
    ];
    final int hash = genre.trim().toLowerCase().codeUnits.fold<int>(
      0,
      (int sum, int unit) => sum + unit,
    );
    return palette[hash % palette.length];
  }

  // ---------------------------------------------------------------------------
  // Members.
  // ---------------------------------------------------------------------------

  Member addMember({
    required String name,
    required String email,
    required String phone,
    required MembershipTier tier,
  }) {
    final String cleanName = name.trim();
    final String cleanEmail = email.trim().toLowerCase();
    if (cleanName.isEmpty) {
      throw LibraryException('A member needs a name.');
    }
    if (!_looksLikeEmail(cleanEmail)) {
      throw LibraryException('Enter a valid email address.');
    }
    if (_members.any((Member member) => member.email == cleanEmail)) {
      throw LibraryException('A member with this email already exists.');
    }

    _idCounter += 1;
    final Member member = Member(
      id: 'M-${_idCounter + 3000}',
      name: cleanName,
      email: cleanEmail,
      phone: phone.trim(),
      tier: tier,
      joinedAt: DateTime.now(),
    );
    _members.add(member);
    notifyListeners();
    return member;
  }

  void updateMember({
    required String id,
    required String name,
    required String email,
    required String phone,
    required MembershipTier tier,
    required bool isActive,
  }) {
    final int index = _members.indexWhere((Member member) => member.id == id);
    if (index == -1) {
      throw LibraryException('This member could not be found.');
    }
    final String cleanEmail = email.trim().toLowerCase();
    if (!_looksLikeEmail(cleanEmail)) {
      throw LibraryException('Enter a valid email address.');
    }
    if (_members.any(
      (Member member) => member.email == cleanEmail && member.id != id,
    )) {
      throw LibraryException('A member with this email already exists.');
    }
    if (!isActive && activeLoanCountForMember(id) > 0) {
      throw LibraryException(
        'Return the books on loan before deactivating this membership.',
      );
    }
    _members[index] = _members[index].copyWith(
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      tier: tier,
      isActive: isActive,
    );
    notifyListeners();
  }

  void deleteMember(String id) {
    final Member? member = memberById(id);
    if (member == null) {
      throw LibraryException('This member could not be found.');
    }
    if (activeLoanCountForMember(id) > 0) {
      throw LibraryException(
        '“${member.name}” still has books on loan.',
      );
    }
    _members.removeWhere((Member item) => item.id == id);
    _loans.removeWhere((Loan loan) => loan.memberId == id);
    notifyListeners();
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  // ---------------------------------------------------------------------------
  // Loans.
  // ---------------------------------------------------------------------------

  Loan issueLoan({
    required String bookId,
    required String memberId,
    required int days,
  }) {
    final Book? book = bookById(bookId);
    if (book == null) {
      throw LibraryException('Choose a book to lend.');
    }
    final Member? member = memberById(memberId);
    if (member == null) {
      throw LibraryException('Choose a member to lend to.');
    }
    if (!member.isActive) {
      throw LibraryException('${member.name} has an inactive membership.');
    }
    if (book.availableCopies < 1) {
      throw LibraryException('No copies of “${book.title}” are on the shelf.');
    }
    if (activeLoanCountForMember(memberId) >= member.loanLimit) {
      throw LibraryException(
        '${member.name} already holds ${member.loanLimit} books — the limit for '
        '${member.tier.label.toLowerCase()} members.',
      );
    }
    final bool duplicate = _loans.any(
      (Loan loan) =>
          loan.bookId == bookId && loan.memberId == memberId && loan.isActive,
    );
    if (duplicate) {
      throw LibraryException(
        '${member.name} already has a copy of “${book.title}”.',
      );
    }

    _idCounter += 1;
    final Loan loan = Loan(
      id: 'L-${_idCounter + 4000}',
      bookId: bookId,
      memberId: memberId,
      issuedAt: DateTime.now(),
      dueDate: todayPlus(days),
    );
    _loans.add(loan);
    _replaceBook(book.copyWith(availableCopies: book.availableCopies - 1));
    notifyListeners();
    return loan;
  }

  Loan returnLoan(String loanId) {
    final int index = _loans.indexWhere((Loan loan) => loan.id == loanId);
    if (index == -1) {
      throw LibraryException('This loan could not be found.');
    }
    final Loan loan = _loans[index];
    if (loan.isReturned) {
      throw LibraryException('This copy has already been returned.');
    }
    final Book? book = bookById(loan.bookId);
    final Loan returned = loan.copyWith(returnedAt: DateTime.now());
    _loans[index] = returned;
    if (book != null) {
      _replaceBook(book.copyWith(
        availableCopies: math.min(book.totalCopies, book.availableCopies + 1),
      ));
    }
    notifyListeners();
    return returned;
  }

  Loan renewLoan(String loanId, {int days = 7}) {
    final int index = _loans.indexWhere((Loan loan) => loan.id == loanId);
    if (index == -1) {
      throw LibraryException('This loan could not be found.');
    }
    final Loan loan = _loans[index];
    if (loan.isReturned) {
      throw LibraryException('Returned loans cannot be renewed.');
    }
    final Loan renewed = loan.copyWith(
      dueDate: loan.dueDate.add(Duration(days: days)),
    );
    _loans[index] = renewed;
    notifyListeners();
    return renewed;
  }

  void _replaceBook(Book updated) {
    final int index = _books.indexWhere((Book book) => book.id == updated.id);
    if (index != -1) {
      _books[index] = updated;
    }
  }

  // ---------------------------------------------------------------------------
  // Utilities.
  // ---------------------------------------------------------------------------

  /// CSV of the catalogue, used by the export action on the Books screen.
  String booksAsCsv() {
    final StringBuffer buffer = StringBuffer(
      'Title,Author,ISBN,Genre,Year,Shelf,Copies,Available\n',
    );
    for (final Book book in _books) {
      buffer.writeln(
        '"${_csv(book.title)}","${_csv(book.author)}",'
        '"${_csv(book.isbn)}","${_csv(book.genre)}",'
        '${book.year},"${_csv(book.shelf)}",'
        '${book.totalCopies},${book.availableCopies}',
      );
    }
    return buffer.toString();
  }

  static String _csv(String value) => value.replaceAll('"', '""');

  /// Restores the catalogue that ships with the app.
  void resetToDemoData() {
    final LibrarySeed seed = buildSeed();
    _books
      ..clear()
      ..addAll(seed.books);
    _members
      ..clear()
      ..addAll(seed.members);
    _loans
      ..clear()
      ..addAll(seed.loans);
    notifyListeners();
  }
}

/// Provides the [LibraryStore] to the widget tree without extra packages.
class LibraryScope extends InheritedNotifier<LibraryStore> {
  const LibraryScope({
    super.key,
    required LibraryStore store,
    required super.child,
  }) : super(notifier: store);

  static LibraryStore of(BuildContext context) {
    final LibraryScope? scope =
        context.dependOnInheritedWidgetOfExactType<LibraryScope>();
    assert(scope != null, 'LibraryScope is missing above this widget.');
    return scope!.notifier!;
  }

  /// Reads the store without subscribing to changes — for callbacks.
  static LibraryStore read(BuildContext context) {
    final LibraryScope? scope =
        context.getInheritedWidgetOfExactType<LibraryScope>();
    assert(scope != null, 'LibraryScope is missing above this widget.');
    return scope!.notifier!;
  }
}
