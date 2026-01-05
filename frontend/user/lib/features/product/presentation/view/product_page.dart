import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';
import 'package:go_router/go_router.dart';

class ProductPage extends StatefulWidget {
  final String? categoryId;
  const ProductPage({super.key, this.categoryId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProductViewmodel>().getAllProduct(
        categoryId: widget.categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewmodel>();

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (vm.errorMessage != null) {
      return Scaffold(body: Center(child: Text(vm.errorMessage!)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sản phẩm")),
      body: RefreshIndicator(
        onRefresh: () => vm.getAllProduct(categoryId: widget.categoryId),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final p = vm.products[i];
            final price = p.variants.isNotEmpty ? p.variants.first.price : 0;
            final stock = p.variants.isNotEmpty
                ? p.variants.first.stockQuantity
                : 0;
            return ListTile(
              title: Text(p.name),
              subtitle: Text(p.description),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$price"),
                  Text("Kho: $stock", style: const TextStyle(fontSize: 12)),
                ],
              ),
              onTap: () => context.go("/products/${p.id}"),
            );
          },
        ),
      ),
    );
  }
}
