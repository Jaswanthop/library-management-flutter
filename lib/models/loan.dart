import '../utils/formatters.dart';

/// A borrow record linking one [Book] to one [Member].
class Loan {
  const Loan({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.issuedAt,
    required this.dueDate,
    this.returnedAt,
  });

  final String id;
  final String bookId;
  final String memberId;
  final DateTime issuedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;

  bool get isReturned => returnedAt != null;

  bool get isActive => returnedAt == null;

  bool get isOverdue => isActive && daysUntil(dueDate) < 0;

  int get overdueDays {
    if (!isOverdue) return 0;
    return -daysUntil(dueDate);
  }

  Loan copyWith({
    DateTime? dueDate,
    DateTime? returnedAt,
  }) {
    return Loan(
      id: id,
      bookId: bookId,
      memberId: memberId,
      issuedAt: issuedAt,
      dueDate: dueDate ?? this.dueDate,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }
}
