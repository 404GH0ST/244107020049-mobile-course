import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk (AsyncValue)'),
        actions: [
          IconButton(
            tooltip: ProductsNotifier.simulateError
                ? 'Mode Error Aktif'
                : 'Mode Normal Aktif',
            icon: Icon(
              ProductsNotifier.simulateError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
            ),
            onPressed: () {
              ProductsNotifier.simulateError = !ProductsNotifier.simulateError;
              ref.invalidate(productsProvider);
            },
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat produk dari server...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(productsProvider),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(products[index]),
            subtitle: Text('Item #${index + 1}'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(productsProvider.notifier).refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
