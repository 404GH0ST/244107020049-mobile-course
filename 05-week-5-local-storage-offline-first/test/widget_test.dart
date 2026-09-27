import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myapp/main.dart';
import 'package:myapp/data/local/note.dart';
import 'package:myapp/data/repositories/note_repository.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items = const []})
      : super(openDb: () => throw UnimplementedError());

  final List<Note> items;

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;
}

void main() {
  testWidgets('OfflineNotesApp widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(
            FakeNoteRepository(
              items: [
                Note(
                  id: 1,
                  title: 'Catatan Tes',
                  body: 'Isi catatan tes',
                  updatedAt: DateTime(2026, 9, 27),
                  dirty: false,
                ),
              ],
            ),
          ),
        ],
        child: const OfflineNotesApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Offline Notes'), findsOneWidget);
    expect(find.text('Catatan Tes'), findsOneWidget);
  });
}
