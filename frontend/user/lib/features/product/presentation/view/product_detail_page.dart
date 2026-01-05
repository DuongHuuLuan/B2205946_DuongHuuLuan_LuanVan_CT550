import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProductViewmodel>().productDetail(widget.productId),
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
    final product = vm.product;
    if (product == null) return const SizedBox();

    final selected = product.variants.firstWhere(
      (v) => v.id == vm.selectedVariantId,
      orElse: () => product.variants.first,
    );

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(product.description),
            const SizedBox(height: 12),
            Text("Giá: ${selected.price}"),
            Text("Kho: ${selected.stockQuantity}"),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: product.variants.map((v) {
                final isSelected = v.id == vm.selectedVariantId;
                return ChoiceChip(
                  label: Text("${v.colorName} / ${v.size}"),
                  selected: isSelected,
                  onSelected: (_) => vm.selectVariant(v.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
