/// Aturan input login. Satu sumber untuk form dan use case agar keduanya
/// tidak pernah berbeda pendapat tentang input yang valid.
final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Pesan error email, atau `null` bila valid. Spasi di tepi diabaikan.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  return _email.hasMatch(email) ? null : 'Masukkan email yang valid';
}

/// Pesan error kata sandi, atau `null` bila valid.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.trim().isEmpty) return 'Kata sandi wajib diisi';
  return password.length >= 6 ? null : 'Minimal 6 karakter';
}
