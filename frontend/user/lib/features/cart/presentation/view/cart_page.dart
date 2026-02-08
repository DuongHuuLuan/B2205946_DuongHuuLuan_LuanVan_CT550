import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_actions.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_summary.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/cart_table.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/widget/discount_dropdown.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<int> _lastDiscountCategoryIds = {};
  int? _selectedDiscountId;
  double _currentDiscountPercent = 0;

  final Set<int> _selectedCartDetailIds = {};
  bool _selectionTouched = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CartViewmodel>().fetchCart());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CartViewmodel>();
    final cartDetails = vm.cartDetails;
    _ensureSelection(cartDetails);

    final selectedTotal = cartDetails
        .where((detail) => _selectedCartDetailIds.contains(detail.id))
        .fold<double>(0, (sum, detail) => sum + detail.lineTotal);
    final hasSelection = _selectedCartDetailIds.isNotEmpty;
    final allSelected =
        cartDetails.isNotEmpty &&
        _selectedCartDetailIds.length == cartDetails.length;
    final selectedCategoryIds = cartDetails
        .where((detail) => _selectedCartDetailIds.contains(detail.id))
        .map((detail) => vm.categoryIdForDetail(detail.productDetailId))
        .whereType<int>()
        .toSet()
        .toList();
    _requestDiscounts(vm, selectedCategoryIds);

    final bool? selectAllValue = cartDetails.isEmpty
        ? false
        : allSelected
        ? true
        : _selectedCartDetailIds.isEmpty
        ? false
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hàng")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            _HeaderRow(
              selectAllValue: selectAllValue,
              onSelectAll: (value) => _toggleSelectAll(value, cartDetails),
            ),
            const SizedBox(height: 10),

            CartTable(
              cartDetails: cartDetails,
              isLoading: vm.isLoading,
              resolveProduct: vm.productForDetail,
              onRemove: (id) => vm.deleteCartDetail(cartDetailId: id),
              onUpdateQuantity: (id, quantity) =>
                  vm.updateCartDetail(cartDetailId: id, newQuantity: quantity),
              isSelected: (id) => _selectedCartDetailIds.contains(id),
              onSelectChanged: _toggleSelectItem,
            ),
            const SizedBox(height: 16),
            CartActions(
              onContinue: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go("/");
                }
              },
              onRefresh: vm.fetchCart,
              isLoading: vm.isLoading,
            ),
            const SizedBox(height: 20),
            CartSummary(
              total: selectedTotal,
              discountPercent: _currentDiscountPercent,
            ),
            const SizedBox(height: 16),
            _CheckoutButton(
              onPressed: hasSelection
                  ? () {
                      final selected = cartDetails
                          .where(
                            (detail) =>
                                _selectedCartDetailIds.contains(detail.id),
                          )
                          .toList();
                      context.go(
                        "/order",
                        extra: {
                          "details": selected,
                          "discountPercent": _currentDiscountPercent,
                        },
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 16),

            DiscountDropdown(
              discounts: vm.discounts,
              isLoading: vm.isDiscountLoading,
              selectedId: _selectedDiscountId,
              onChanged: (id) {
                setState(() {
                  _selectedDiscountId = id;
                  if (id == null) {
                    _currentDiscountPercent = 0;
                  }

                  //tìm discout trong danh sách để lấy %
                  final selected = vm.discounts.firstWhere((d) => d.id == id);
                  _currentDiscountPercent = selected.percent.toDouble();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelectAll(bool? value, List<CartDetail> cartDetails) {
    setState(() {
      _selectionTouched = true;
      if (value == true) {
        _selectedCartDetailIds
          ..clear()
          ..addAll(cartDetails.map((detail) => detail.id));
      } else {
        _selectedCartDetailIds.clear();
      }
    });
  }

  void _toggleSelectItem(int cartDetailId, bool selected) {
    setState(() {
      _selectionTouched = true;
      if (selected) {
        _selectedCartDetailIds.add(cartDetailId);
      } else {
        _selectedCartDetailIds.remove(cartDetailId);
      }
    });
  }

  void _requestDiscounts(CartViewmodel vm, List<int> categoryIds) {
    final normalized = categoryIds.toSet();
    if (normalized.isEmpty) {
      if (_lastDiscountCategoryIds.isNotEmpty) {
        _lastDiscountCategoryIds.clear();
        vm.fetchDiscountsForCategories(const []);
      }
      return;
    }
    if (_lastDiscountCategoryIds.length == normalized.length &&
        _lastDiscountCategoryIds.containsAll(normalized)) {
      return;
    }
    _lastDiscountCategoryIds
      ..clear()
      ..addAll(normalized);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      vm.fetchDiscountsForCategories(normalized.toList());
    });
  }

  void _ensureSelection(List<CartDetail> cartDetails) {
    final currentIds = cartDetails.map((detail) => detail.id).toSet();
    final needsCleanup = _selectedCartDetailIds.any(
      (id) => !currentIds.contains(id),
    );
    final shouldAutoSelect =
        !_selectionTouched &&
        _selectedCartDetailIds.isEmpty &&
        cartDetails.isNotEmpty;
    if (!needsCleanup && !shouldAutoSelect) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (needsCleanup) {
          _selectedCartDetailIds.removeWhere((id) => !currentIds.contains(id));
        }
        if (shouldAutoSelect) {
          _selectedCartDetailIds.addAll(currentIds);
        }
      });
    });
  }
}

class _HeaderRow extends StatelessWidget {
  final bool? selectAllValue;
  final ValueChanged<bool?> onSelectAll;
  const _HeaderRow({required this.selectAllValue, required this.onSelectAll});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headerStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Checkbox(
                value: selectAllValue,
                tristate: true,
                onChanged: onSelectAll,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              Text("SẢN PHẨM", style: headerStyle),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "SỐ LƯỢNG",
            textAlign: TextAlign.center,
            style: headerStyle,
          ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CheckoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text("TIẾN HÀNH THANH TOÁN"),
      ),
    );
  }
}
