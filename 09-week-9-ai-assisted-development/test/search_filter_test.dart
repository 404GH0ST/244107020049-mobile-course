import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/data/local/note.dart';
import 'package:myapp/domain/usecases/search_notes.dart';

void main() {
  final sampleNotes = [
    Note(
      id: 1,
      title: 'Belanja Mingguan',
      body: 'Beli susu, telur, dan roti gandum.',
      updatedAt: DateTime(2026, 10, 20),
    ),
    Note(
      id: 2,
      title: 'Daftar Belanja Pasar',
      body: 'Beli sayur bayam dan wortel segar.',
      updatedAt: DateTime(2026, 10, 21),
    ),
    Note(
      id: 3,
      title: 'Kuliah Pemrograman Mobile',
      body: 'Mengerjakan codelab Minggu 9 AI-assisted development.',
      updatedAt: DateTime(2026, 10, 22),
    ),
    Note(
      id: 4,
      title: 'Catatan Rapat Tim PBL',
      body: 'Membahas integrasi link checker dan review PR.',
      updatedAt: DateTime(2026, 10, 23),
    ),
  ];

  group('filterNotes pure domain logic', () {
    test('query kosong kembalikan seluruh catatan', () {
      final result = filterNotes(sampleNotes, '');
      expect(result.length, equals(4));
      expect(result, equals(sampleNotes));
    });

    test(
      'query whitespace saja dinormalisasi dan kembalikan seluruh catatan',
      () {
        final result = filterNotes(sampleNotes, '   ');
        expect(result.length, equals(4));
      },
    );

    test('filter abaikan huruf besar/kecil', () {
      final result = filterNotes(sampleNotes, 'belanja');
      expect(result, hasLength(2));
      expect(result.map((n) => n.id), containsAll([1, 2]));
    });

    test('filter huruf besar menghasilkan hasil yang sama', () {
      final result = filterNotes(sampleNotes, 'BELANJA');
      expect(result, hasLength(2));
      expect(result.map((n) => n.id), containsAll([1, 2]));
    });

    test('query tak cocok kembalikan kosong', () {
      final result = filterNotes(sampleNotes, 'zzz-tak-ada');
      expect(result, isEmpty);
    });

    test('filter substring di tengah kata', () {
      final result = filterNotes(sampleNotes, 'graman');
      expect(result, hasLength(1));
      expect(result.first.id, equals(3));
    });

    test(
      'SearchNotesUseCase mengeksekusi logika yang sama dengan filterNotes',
      () {
        const useCase = SearchNotesUseCase();
        final result = useCase(sampleNotes, 'PBL');
        expect(result, hasLength(1));
        expect(result.first.id, equals(4));
      },
    );
  });
}
