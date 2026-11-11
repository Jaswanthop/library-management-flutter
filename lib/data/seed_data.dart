import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../utils/formatters.dart';

/// Raw state used to bootstrap the store.
class LibrarySeed {
  LibrarySeed({
    required this.books,
    required this.members,
    required this.loans,
  });

  final List<Book> books;
  final List<Member> members;
  final List<Loan> loans;
}

const List<Color> _coverPalette = <Color>[
  Color(0xFF1F5A4A),
  Color(0xFF2B4C7E),
  Color(0xFF7A3E48),
  Color(0xFF8A5A22),
  Color(0xFF3F4E8C),
  Color(0xFF5C3D6E),
  Color(0xFF2D6A6A),
  Color(0xFF7B4B2A),
];

/// Demo catalogue so the app is useful the first time it is opened.
LibrarySeed buildSeed() {
  final DateTime now = DateTime.now();

  final List<Book> books = <Book>[
    Book(
      id: 'B-1001',
      title: 'The Pragmatic Programmer',
      author: 'Andrew Hunt & David Thomas',
      isbn: '978-0201616224',
      genre: 'Software',
      year: 1999,
      totalCopies: 4,
      availableCopies: 4,
      shelf: 'A-12',
      addedAt: now.subtract(const Duration(days: 340)),
      coverColor: _coverPalette[0],
    ),
    Book(
      id: 'B-1002',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '978-0132350884',
      genre: 'Software',
      year: 2008,
      totalCopies: 3,
      availableCopies: 3,
      shelf: 'A-14',
      addedAt: now.subtract(const Duration(days: 310)),
      coverColor: _coverPalette[1],
    ),
    Book(
      id: 'B-1003',
      title: 'Designing Data-Intensive Applications',
      author: 'Martin Kleppmann',
      isbn: '978-1449373320',
      genre: 'Software',
      year: 2017,
      totalCopies: 2,
      availableCopies: 2,
      shelf: 'A-19',
      addedAt: now.subtract(const Duration(days: 240)),
      coverColor: _coverPalette[2],
    ),
    Book(
      id: 'B-1004',
      title: 'Sapiens: A Brief History of Humankind',
      author: 'Yuval Noah Harari',
      isbn: '978-0062316097',
      genre: 'History',
      year: 2011,
      totalCopies: 5,
      availableCopies: 5,
      shelf: 'C-03',
      addedAt: now.subtract(const Duration(days: 420)),
      coverColor: _coverPalette[3],
    ),
    Book(
      id: 'B-1005',
      title: 'A Brief History of Time',
      author: 'Stephen Hawking',
      isbn: '978-0553380163',
      genre: 'Science',
      year: 1988,
      totalCopies: 3,
      availableCopies: 3,
      shelf: 'D-07',
      addedAt: now.subtract(const Duration(days: 500)),
      coverColor: _coverPalette[4],
    ),
    Book(
      id: 'B-1006',
      title: 'The Silent Patient',
      author: 'Alex Michaelides',
      isbn: '978-1250301697',
      genre: 'Thriller',
      year: 2019,
      totalCopies: 4,
      availableCopies: 4,
      shelf: 'F-21',
      addedAt: now.subtract(const Duration(days: 120)),
      coverColor: _coverPalette[5],
    ),
    Book(
      id: 'B-1007',
      title: 'Atomic Habits',
      author: 'James Clear',
      isbn: '978-0735211292',
      genre: 'Self-help',
      year: 2018,
      totalCopies: 6,
      availableCopies: 6,
      shelf: 'E-02',
      addedAt: now.subtract(const Duration(days: 200)),
      coverColor: _coverPalette[6],
    ),
    Book(
      id: 'B-1008',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      isbn: '978-0062315007',
      genre: 'Fiction',
      year: 1988,
      totalCopies: 5,
      availableCopies: 5,
      shelf: 'B-08',
      addedAt: now.subtract(const Duration(days: 610)),
      coverColor: _coverPalette[7],
    ),
    Book(
      id: 'B-1009',
      title: 'Educated',
      author: 'Tara Westover',
      isbn: '978-0399590504',
      genre: 'Memoir',
      year: 2018,
      totalCopies: 3,
      availableCopies: 3,
      shelf: 'C-11',
      addedAt: now.subtract(const Duration(days: 150)),
      coverColor: _coverPalette[0],
    ),
    Book(
      id: 'B-1010',
      title: 'Thinking, Fast and Slow',
      author: 'Daniel Kahneman',
      isbn: '978-0374533557',
      genre: 'Psychology',
      year: 2011,
      totalCopies: 3,
      availableCopies: 3,
      shelf: 'D-15',
      addedAt: now.subtract(const Duration(days: 380)),
      coverColor: _coverPalette[1],
    ),
    Book(
      id: 'B-1011',
      title: 'The Name of the Wind',
      author: 'Patrick Rothfuss',
      isbn: '978-0756404741',
      genre: 'Fantasy',
      year: 2007,
      totalCopies: 2,
      availableCopies: 2,
      shelf: 'F-04',
      addedAt: now.subtract(const Duration(days: 90)),
      coverColor: _coverPalette[2],
    ),
    Book(
      id: 'B-1012',
      title: 'Deep Work',
      author: 'Cal Newport',
      isbn: '978-1455586691',
      genre: 'Self-help',
      year: 2016,
      totalCopies: 4,
      availableCopies: 4,
      shelf: 'E-05',
      addedAt: now.subtract(const Duration(days: 260)),
      coverColor: _coverPalette[3],
    ),
  ];

  final List<Member> members = <Member>[
    Member(
      id: 'M-2001',
      name: 'Aarav Mehta',
      email: 'aarav.mehta@example.com',
      phone: '+91 98765 43210',
      tier: MembershipTier.student,
      joinedAt: now.subtract(const Duration(days: 320)),
    ),
    Member(
      id: 'M-2002',
      name: 'Priya Sharma',
      email: 'priya.sharma@example.com',
      phone: '+91 91234 56780',
      tier: MembershipTier.faculty,
      joinedAt: now.subtract(const Duration(days: 690)),
    ),
    Member(
      id: 'M-2003',
      name: 'Daniel Okafor',
      email: 'daniel.okafor@example.com',
      phone: '+44 7700 900123',
      tier: MembershipTier.community,
      joinedAt: now.subtract(const Duration(days: 84)),
    ),
    Member(
      id: 'M-2004',
      name: 'Sofia Ramirez',
      email: 'sofia.ramirez@example.com',
      phone: '+34 612 345 678',
      tier: MembershipTier.student,
      joinedAt: now.subtract(const Duration(days: 210)),
    ),
    Member(
      id: 'M-2005',
      name: 'Liam Chen',
      email: 'liam.chen@example.com',
      phone: '+1 415 555 0132',
      tier: MembershipTier.faculty,
      joinedAt: now.subtract(const Duration(days: 780)),
    ),
    Member(
      id: 'M-2006',
      name: 'Ananya Iyer',
      email: 'ananya.iyer@example.com',
      phone: '+91 99887 76655',
      tier: MembershipTier.student,
      joinedAt: now.subtract(const Duration(days: 41)),
    ),
    Member(
      id: 'M-2007',
      name: 'Noah Williams',
      email: 'noah.williams@example.com',
      phone: '+1 202 555 0177',
      tier: MembershipTier.community,
      joinedAt: now.subtract(const Duration(days: 520)),
      isActive: false,
    ),
  ];

  final List<Loan> loans = <Loan>[
    // Currently on loan, overdue.
    Loan(
      id: 'L-3001',
      bookId: 'B-1001',
      memberId: 'M-2001',
      issuedAt: now.subtract(const Duration(days: 33)),
      dueDate: todayPlus(-12),
    ),
    // Currently on loan, due soon.
    Loan(
      id: 'L-3002',
      bookId: 'B-1004',
      memberId: 'M-2002',
      issuedAt: now.subtract(const Duration(days: 5)),
      dueDate: todayPlus(9),
    ),
    // Currently on loan.
    Loan(
      id: 'L-3003',
      bookId: 'B-1007',
      memberId: 'M-2004',
      issuedAt: now.subtract(const Duration(days: 2)),
      dueDate: todayPlus(12),
    ),
    // Currently on loan, overdue.
    Loan(
      id: 'L-3004',
      bookId: 'B-1006',
      memberId: 'M-2005',
      issuedAt: now.subtract(const Duration(days: 40)),
      dueDate: todayPlus(-4),
    ),
    // Returned history.
    Loan(
      id: 'L-3005',
      bookId: 'B-1002',
      memberId: 'M-2003',
      issuedAt: now.subtract(const Duration(days: 60)),
      dueDate: now.subtract(const Duration(days: 46)),
      returnedAt: now.subtract(const Duration(days: 48)),
    ),
    Loan(
      id: 'L-3006',
      bookId: 'B-1008',
      memberId: 'M-2006',
      issuedAt: now.subtract(const Duration(days: 26)),
      dueDate: now.subtract(const Duration(days: 12)),
      returnedAt: now.subtract(const Duration(days: 14)),
    ),
    Loan(
      id: 'L-3007',
      bookId: 'B-1010',
      memberId: 'M-2002',
      issuedAt: now.subtract(const Duration(days: 90)),
      dueDate: now.subtract(const Duration(days: 76)),
      returnedAt: now.subtract(const Duration(days: 80)),
    ),
    Loan(
      id: 'L-3008',
      bookId: 'B-1012',
      memberId: 'M-2001',
      issuedAt: now.subtract(const Duration(days: 140)),
      dueDate: now.subtract(const Duration(days: 126)),
      returnedAt: now.subtract(const Duration(days: 130)),
    ),
    Loan(
      id: 'L-3009',
      bookId: 'B-1005',
      memberId: 'M-2005',
      issuedAt: now.subtract(const Duration(days: 190)),
      dueDate: now.subtract(const Duration(days: 176)),
      returnedAt: now.subtract(const Duration(days: 178)),
    ),
  ];

  // Keep availability consistent with the active loans above.
  final Map<String, int> activeByBook = <String, int>{};
  for (final Loan loan in loans) {
    if (loan.isActive) {
      activeByBook.update(loan.bookId, (int v) => v + 1, ifAbsent: () => 1);
    }
  }

  final List<Book> consistentBooks = books
      .map((Book book) => book.copyWith(
            availableCopies:
                book.totalCopies - (activeByBook[book.id] ?? 0),
          ))
      .toList();

  return LibrarySeed(
    books: consistentBooks,
    members: members,
    loans: loans,
  );
}
