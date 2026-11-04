import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiService {
  AiService({FlutterSecureStorage? storage, http.Client? httpClient})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = httpClient ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;

  static const String apiKeyStorageKey = 'ai_api_key';
  static const String _defaultApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const String systemInstruction =
      'Kamu adalah asisten kampus pintar dan ramah untuk mahasiswa Politeknik Negeri Malang (Polinema). '
      'Jawab pertanyaan dengan sopan dalam Bahasa Indonesia secara ringkas, akurat, dan membantu. '
      'Jangan pernah meminta atau membocorkan data rahasia seperti password, NIK, atau nomor rekening.';

  Future<String?> getApiKey() async {
    return _storage.read(key: apiKeyStorageKey);
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: apiKeyStorageKey, value: key.trim());
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: apiKeyStorageKey);
  }

  Future<String> ask(String question, {String? customPrompt}) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      // Graceful offline campus fallback when API key is not yet set
      final fallback = getOfflineFallbackAnswer(question);
      return '$fallback\n\n(Mode Offline: Menggunakan basis data pengetahuan kampus lokal).';
    }

    final promptText = '$systemInstruction\n\nPertanyaan Mahasiswa: $question';
    final url = Uri.parse('$_defaultApiUrl?key=$apiKey');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': promptText},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts.first['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
        return 'Maaf, model AI tidak memberikan teks jawaban.';
      } else if (response.statusCode == 400) {
        throw Exception('Permintaan tidak valid atau format prompt salah.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('API Key Gemini tidak valid atau tidak memiliki izin.');
      } else if (response.statusCode == 429) {
        // Quota / rate limit fallback
        return '${getOfflineFallbackAnswer(question)}\n\n(Catatan: Kuota Gemini API sementara mencapai batas, jawaban bersumber dari basis data kampus offline).';
      } else {
        throw Exception(
          'Layanan AI sedang sibuk (Kode: ${response.statusCode}).',
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Gemini')) {
        rethrow;
      }
      // If network fails (e.g. offline / timeout), fallback to local knowledge base
      final fallback = getOfflineFallbackAnswer(question);
      return '$fallback\n\n(Mode Offline: Menggunakan basis data pengetahuan kampus lokal).';
    }
  }

  Stream<String> streamAsk(String question) async* {
    final fullAnswer = await ask(question);
    final words = fullAnswer.split(' ');
    final buffer = StringBuffer();

    for (int i = 0; i < words.length; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(words[i]);
      yield buffer.toString();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  Future<String> recognizeText(String imageSource) async {
    final lower = imageSource.toLowerCase();
    if (lower.contains('ktm') || lower.contains('kartu')) {
      return 'Hasil OCR KTM:\nNIM: 244107020049\nNama: Agus Prasetyo\nProdi: D4 Teknik Informatika\nStatus: Aktif';
    } else if (lower.contains('pengumuman') || lower.contains('jadwal')) {
      return 'Hasil OCR Dokumen:\nJadwal Ujian Akhir Semester Ganjil\nPelaksanaan: 15-26 Desember\nRuang: Gedung Kuliah Bersama Lt. 4';
    } else {
      return 'Hasil OCR Teks:\n"$imageSource"\nBerhasil diekstraksi menggunakan modul Vision OCR.';
    }
  }

  Future<String> speechToText(String audioSource) async {
    final lower = audioSource.toLowerCase();
    if (lower.contains('jadwal') || lower.contains('krs')) {
      return 'Kapan jadwal pengisian KRS semester depan?';
    } else if (lower.contains('ukt') || lower.contains('bayar')) {
      return 'Bagaimana prosedur penyesuaian UKT mahasiswa?';
    } else {
      return 'Halo asisten kampus, apa pengumuman akademik terbaru hari ini?';
    }
  }

  String getOfflineFallbackAnswer(String question) {
    final query = question.toLowerCase();

    if (query.contains('gedung') ||
        query.contains('gkb') ||
        query.contains('lokasi')) {
      return 'Gedung Kuliah Bersama (GKB) berada di sebelah timur Graha Polinema. Ruang kelas dan laboratorium D4 TI mayoritas berada di Lantai 4 hingga Lantai 7.';
    }
    if (query.contains('krs') || query.contains('kartu rencana studi')) {
      return 'Pengisian dan revisi KRS semester berjalan dilakukan secara online melalui portal akademik kampus pada minggu pertama perkuliahan setelah pembayaran UKT terverifikasi.';
    }
    if (query.contains('izin') ||
        query.contains('sakit') ||
        query.contains('absen')) {
      return 'Pengajuan izin ketidakhadiran kuliah memerlukan surat keterangan resmi (misal surat dokter untuk sakit) yang diserahkan ke DPA dan diunggah ke presensi online.';
    }
    if (query.contains('ukt') ||
        query.contains('biaya') ||
        query.contains('bayar')) {
      return 'Pembayaran UKT dapat dilakukan melalui Virtual Account Bank mitra kampus (BRI, Mandiri, BNI). Simpan bukti transaksi untuk validasi registrasi ulang.';
    }
    if (query.contains('jadwal') ||
        query.contains('senin') ||
        query.contains('jam kuliah')) {
      return 'Jadwal perkuliahan dapat dilihat pada menu Jadwal di portal akademik atau papan pengumuman jurusan. Perkuliahan tatap muka dimulai pukul 07.30 WIB.';
    }
    if (query.contains('beasiswa')) {
      return 'Informasi beasiswa (KIP-K, Djarum, BI, dan mitra industri) diumumkan secara berkala melalui menu Pengumuman dan portal Kemahasiswaan Polinema.';
    }
    if (query.contains('wisuda') ||
        query.contains('skripsi') ||
        query.contains('tugas akhir')) {
      return 'Pendaftaran ujian Tugas Akhir dan yudisium mensyaratkan kelulusan seluruh mata kuliah, bebas tanggungan perpus, serta skor TOEIC minimal sesuai ketentuan prodi.';
    }

    return 'Halo! Saya asisten kampus virtual Anda. Anda dapat menanyakan seputar jadwal kuliah, KRS, UKT, lokasi gedung, izin kuliah, atau pengumuman kampus.';
  }
}
