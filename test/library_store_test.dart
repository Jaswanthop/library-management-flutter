import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfwise/data/library_store.dart';
import 'package:shelfwise/models/book.dart';
import 'package:shelfwise/models/member.dart';

Book _book({
  String id = 'B-1',
  int totalCopies = 2,
  int availableCopies = 2,
  String isbn = '978-0000000001',
}) {
  return Book(
    id: id,
    title: 'Test Driven Development',
    author: 'Kent Beck',
    isbn: isbn,
    genre: 'Software',
    year: 2002,
    totalCopies: totalCopies,
    availableCopies: availableCopies,
    shelf: 'T-01',
    addedAt: DateTime(2024, 1, 1),
    coverColor: const Color(0xFF1F5A4A),
  );
}

Member _member({String id = 'M-1', String email = 'reader@example.com'}) {
  return Member(
    id: id,
    name: 'Test Reader',
    email: email,
    phone: '000',
    tier: MembershipTier.student,
    joinedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('LibraryStore loans', () {
    late LibraryStore store;

    setUp(() {
      store = LibraryStore(
        books: <Book>[_book()],
        members: <Member>[_member()],
      );
    });

    test('seeded store starts with a coherent catalogue', () {
      final LibraryStore seeded = LibraryStore.seeded();
      expect(seeded.books, isNotEmpty);
      expect(seeded.members, isNotEmpty);
      expect(
        seeded.totalCopies,
        seeded.availableCopies + seeded.onLoanCopies,
      );
      for (final Book book in seeded.books) {
        expect(book.availableCopies, lessThanOrEqualTo(book.totalCopies));
        expect(book.availableCopies, greaterThanOrEqualTo(0));
      }
    });

    test('issuing a loan lowers availability and records history', () {
      final int before = store.availableCopies;
      final loan = store.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 14);

      expect(store.availableCopies, before - 1);
      expect(store.activeLoans, 1);
      expect(loan.isActive, isTrue);
      expect(store.activeLoanCountForMember('M-1'), 1);
      expect(store.bookById('B-1')!.availableCopies, 1);
    });

    test('returning a loan puts the copy back on the shelf', () {
      final loan = store.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 14);
      store.returnLoan(loan.id);

      expect(store.activeLoans, 0);
      expect(store.bookById('B-1')!.availableCopies, 2);
      expect(store.loans.single.isReturned, isTrue);
      expect(() => store.returnLoan(loan.id), throwsA(isA<LibraryException>()));
    });

    test('cannot issue a title with no copies available', () {
      store = LibraryStore(
        books: <Book>[_book(availableCopies: 0)],
        members: <Member>[_member()],
      );
      expect(
        () => store.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 7),
        throwsA(isA<LibraryException>()),
      );
    });

    test('cannot lend the same title twice to one member', () {
      store.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 7);
      expect(
        () => store.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 7),
        throwsA(isA<LibraryException>()),
      );
    });

    test('respects the tier loan limit', () {
      // Students may hold up to three books.
      final LibraryStore library = LibraryStore(
        books: <Book>[
          _book(id: 'B-1', isbn: '1'),
          _book(id: 'B-2', isbn: '2'),
          _book(id: 'B-3', isbn: '3'),
          _book(id: 'B-4', isbn: '4'),
        ],
        members: <Member>[_member()],
      );
      for (final String id in <String>['B-1', 'B-2', 'B-3']) {
        library.issueLoan(bookId: id, memberId: 'M-1', days: 7);
      }
      expect(
        () => library.issueLoan(bookId: 'B-4', memberId: 'M-1', days: 7),
        throwsA(isA<LibraryException>()),
      );
    });

    test('loans can be renewed with a later due date', () {
      final LibraryStore library = LibraryStore(
        books: <Book>[_book()],
        members: <Member>[_member()],
      );
      final loan = library.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 7);
      expect(library.overdueLoans, 0);
      final renewed = library.renewLoan(loan.id, days: 7);
      expect(renewed.dueDate.isAfter(loan.dueDate), isTrue);
      expect(renewed.isActive, isTrue);
    });
  });

  group('catalogue rules', () {
    test('a book with an active loan cannot be deleted', () {
      final LibraryStore store = LibraryStore(
        books: <Book>[_book()],
        members: <Member>[_member()],
      );
      store.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 7);
      expect(
        () => store.deleteBook('B-1'),
        throwsA(isA<LibraryException>()),
      );
    });

    test('copies cannot be reduced below the number on loan', () {
      final LibraryStore store = LibraryStore(
        books: <Book>[_book()],
        members: <Member>[_member()],
      );
      store.issueLoan(bookId: 'B-1', memberId: 'M-1', days: 7);
      expect(
        () => store.updateBook(
          id: 'B-1',
          title: 'Test Driven Development',
          author: 'Kent Beck',
          isbn: '',
          genre: 'Software',
          year: 2002,
          copies: 0,
          shelf: 'T-01',
        ),
        throwsA(isA<LibraryException>()),
      );
    });

    test('duplicate ISBNs are rejected', () {
      final LibraryStore store = LibraryStore(
        books: <Book>[_book()],
        members: <Member>[],
      );
      expect(
        () => store.addBook(
          title: 'Another book',
          author: 'Someone',
          isbn: '9780000000001',
          genre: 'Software',
          year: 2020,
          copies: 1,
          shelf: 'T-02',
        ),
        throwsA(isA<LibraryException>()),
      );
    });

    test('members need a unique, valid email', () {
      final LibraryStore store = LibraryStore(
        books: <Book>[],
        members: <Member>[_member()],
      );
      expect(
        () => store.addMember(
          name: 'Someone Else',
          email: 'not-an-email',
          phone: '',
          tier: MembershipTier.community,
        ),
        throwsA(isA<LibraryException>()),
      );
      expect(
        () => store.addMember(
          name: 'Someone Else',
          email: 'reader@example.com',
          phone: '',
          tier: MembershipTier.community,
        ),
        throwsA(isA<LibraryException>()),
      );
      final Member created = store.addMember(
        name: 'Someone Else',
        email: 'someone@example.com',
        phone: '',
        tier: MembershipTier.faculty,
      );
      expect(created.loanLimit, 6);
      expect(store.members.length, 2);
    });

    test('genre distribution covers every title', () {
      final LibraryStore seeded = LibraryStore.seeded();
      final int total = seeded.genreDistribution.values
          .fold(0, (int a, int b) => a + b);
      expect(total, seeded.totalTitles);
    });

    test('reset restores the demo catalogue', () {
      final LibraryStore store = LibraryStore.seeded();
      final int original = store.books.length;
      store.deleteBook(store.books.last.id);
      expect(store.books.length, original - 1);
      store.resetToDemoData();
      expect(store.books.length, original);
    });
  });
}
