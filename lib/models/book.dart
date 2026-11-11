import 'package:flutter/material.dart';

/// A title held by the library. [availableCopies] tracks how many physical
/// copies are currently on the shelf.
@immutable
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.genre,
    required this.year,
    required this.totalCopies,
    required this.availableCopies,
    required this.shelf,
    required this.addedAt,
    required this.coverColor,
  });

  final String id;
  final String title;
  final String author;
  final String isbn;
  final String genre;
  final int year;
  final int totalCopies;
  final int availableCopies;
  final String shelf;
  final DateTime addedAt;
  final Color coverColor;

  int get onLoanCopies => totalCopies - availableCopies;
  bool get isAvailable => availableCopies > 0;

  Book copyWith({
    String? title,
    String? author,
    String? isbn,
    String? genre,
    int? year,
    int? totalCopies,
    int? availableCopies,
    String? shelf,
    Color? coverColor,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      shelf: shelf ?? this.shelf,
      addedAt: addedAt,
      coverColor: coverColor ?? this.coverColor,
    );
  }
}
