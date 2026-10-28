import '../../data/local/note.dart';

/// Pure domain function to filter notes by title.
///
/// Implements case-insensitive matching and trims extraneous whitespace.
/// When the query is empty or contains only whitespace, all notes are returned.
List<Note> filterNotes(List<Note> notes, String query) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return List<Note>.unmodifiable(notes);
  }
  return notes.where((note) {
    return note.title.toLowerCase().contains(trimmed);
  }).toList();
}

/// Use case class encapsulating the search notes domain logic.
class SearchNotesUseCase {
  const SearchNotesUseCase();

  List<Note> call(List<Note> notes, String query) {
    return filterNotes(notes, query);
  }
}
