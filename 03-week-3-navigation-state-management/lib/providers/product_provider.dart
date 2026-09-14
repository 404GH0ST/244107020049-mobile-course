import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsNotifier extends AsyncNotifier<List<String>> {
  static bool simulateError = false;

  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 2)); // simulasi network
    if (simulateError) {
      throw Exception('Gagal terhubung ke server (HTTP 500)');
    }
    return ['Keyboard Mekanikal', 'Mouse Wireless', 'Monitor 4K'];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<List<String>> _fetch() async {
    await Future.delayed(const Duration(seconds: 1));
    if (simulateError) {
      throw Exception('Gagal terhubung ke server (HTTP 500)');
    }
    return ['Keyboard Mekanikal', 'Mouse Wireless', 'Monitor 4K', 'Headset Gaming'];
  }
}

final productsProvider =
    AsyncNotifierProvider<ProductsNotifier, List<String>>(
        ProductsNotifier.new);
