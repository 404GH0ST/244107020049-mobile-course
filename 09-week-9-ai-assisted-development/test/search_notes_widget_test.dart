import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/data/local/note.dart';
import 'package:myapp/data/prefs.dart';
import 'package:myapp/data/repositories/note_repository.dart';
import 'package:myapp/pages/notes_page.dart';
import 'package:myapp/widgets/search_empty_state.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const []})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> items;

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;
}

class FakePrefsRepository extends PrefsRepository {
  @override
  Future<bool> getDarkMode() async => false;

  @override
  Future<void> setDarkMode(bool val) async {}
}

void main() {
  final testNotes = [
    Note(
      id: 1,
      title: 'Belanja Bulanan',
      body: 'Beli minyak goreng dan beras.',
      updatedAt: DateTime(2026, 10, 25),
    ),
    Note(
      id: 2,
      title: 'Tugas Kuliah Flutter',
      body: 'Selesaikan praktikum Minggu 9 AI-assisted.',
      updatedAt: DateTime(2026, 10, 26),
    ),
    Note(
      id: 3,
      title: 'Belanja Elektronik',
      body: 'Beli kabel USB-C.',
      updatedAt: DateTime(2026, 10, 27),
    ),
  ];

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(items: testNotes),
        ),
      ],
      child: const MaterialApp(home: NotesPage()),
    );
  }

  testWidgets('menampilkan semua catatan dan search bar saat awal dimuat', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search_notes_field')), findsOneWidget);
    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Tugas Kuliah Flutter'), findsOneWidget);
    expect(find.text('Belanja Elektronik'), findsOneWidget);
  });

  testWidgets('mengetik query memfilter daftar catatan', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final searchField = find.byKey(const Key('search_notes_field'));
    await tester.enterText(searchField, 'belanja');
    await tester.pumpAndSettle();

    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Belanja Elektronik'), findsOneWidget);
    expect(find.text('Tugas Kuliah Flutter'), findsNothing);
  });

  testWidgets(
    'query tidak cocok menampilkan SearchEmptyState dan tombol reset',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('search_notes_field'));
      await tester.enterText(searchField, 'zzz-tak-ada');
      await tester.pumpAndSettle();

      expect(find.byType(SearchEmptyState), findsOneWidget);
      expect(find.text('Tidak ada catatan ditemukan'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SearchEmptyState),
          matching: find.textContaining('zzz-tak-ada'),
        ),
        findsOneWidget,
      );
      expect(find.text('Reset Pencarian'), findsOneWidget);

      // Tap tombol reset pencarian
      await tester.tap(find.text('Reset Pencarian'));
      await tester.pumpAndSettle();

      // Seluruh catatan harus kembali ditampilkan
      expect(find.byType(SearchEmptyState), findsNothing);
      expect(find.text('Belanja Bulanan'), findsOneWidget);
      expect(find.text('Tugas Kuliah Flutter'), findsOneWidget);
      expect(find.text('Belanja Elektronik'), findsOneWidget);
    },
  );

  testWidgets('menekan tombol clear pada search bar mengosongkan query', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final searchField = find.byKey(const Key('search_notes_field'));
    await tester.enterText(searchField, 'flutter');
    await tester.pumpAndSettle();

    expect(find.text('Tugas Kuliah Flutter'), findsOneWidget);
    expect(find.text('Belanja Bulanan'), findsNothing);

    final clearButton = find.byKey(const Key('search_clear_button'));
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Belanja Bulanan'), findsOneWidget);
    expect(find.text('Tugas Kuliah Flutter'), findsOneWidget);
    expect(find.text('Belanja Elektronik'), findsOneWidget);
  });
}
