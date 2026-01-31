import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/viewmodel/order_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/widget/address_form.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/widget/address_section.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/widget/payment_section.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/widget/payment_summary.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/widget/product_row.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/widget/shipping_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderPage extends StatefulWidget {
  final List<CartDetail> cartDetails;
  final double discountPercent;
  const OrderPage({
    super.key,
    required this.cartDetails,
    required this.discountPercent,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String _requiredNote = "KHONGCHOXEMHANG";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final vm = context.read<OrderViewmodel>();
      vm.setCartDetails(widget.cartDetails);
      vm.loadInitialData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewmodel>();
    final cartVm = context.read<CartViewmodel>();
    final discountPercent = widget.discountPercent;
    final subtotal = widget.cartDetails.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final discountedTotal = subtotal * (1 - discountPercent / 100);
    final shippingFee = vm.feeTotal ?? 0;
    final totalPayment = discountedTotal + shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán"),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/cart");
            }
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle("Địa chỉ nhận hàng"),
                AddressSection(
                  deliveries: vm.deliveries,
                  selected: vm.selectedDelivery,
                  useSaved: vm.useSavedAddress,
                  onSelect: (info) => vm.selectDelivery(info),
                  onUseNew: () => vm.selectDelivery(null),
                ),
                if (!vm.useSavedAddress || vm.deliveries.isEmpty)
                  AddressForm(
                    nameController: _nameController,
                    phoneController: _phoneController,
                  ),
                if (!vm.useSavedAddress || vm.deliveries.isEmpty)
                  _LocationSelectors(vm: vm),
                const SizedBox(height: 12),
                _SectionTitle("Sản phẩm"),
                ...widget.cartDetails.map((item) {
                  final product = cartVm.productForDetail(item.productDetailId);
                  return ProductRow(
                    detail: item,
                    product: product,
                    discountPercent: discountPercent,
                  );
                }),
                const SizedBox(height: 12),
                _SectionTitle("Phương thức vận chuyển (GHN)"),
                ShippingSection(
                  services: vm.services,
                  selected: vm.selectedService,
                  fee: vm.feeTotal,
                  onSelect: (service) => vm.selectService(service),
                ),
                const SizedBox(height: 12),
                _SectionTitle("Phương thức thanh toán"),
                PaymentSection(
                  methods: vm.paymentMethods,
                  selected: vm.selectedPayment,
                  onSelect: (value) {
                    setState(() {
                      vm.selectedPayment = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _SectionTitle("Chi tiết thanh toán"),
                PaymentSummary(
                  subtotal: subtotal,
                  discountPercent: discountPercent,
                  shippingFee: shippingFee,
                  total: totalPayment,
                ),
                const SizedBox(height: 20),
                _NoteSection(
                  noteController: _noteController,
                  requiredNote: _requiredNote,
                  onRequiredNoteChanged: (value) {
                    if (value == null) return;
                    setState(() => _requiredNote = value);
                  },
                ),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          _BottomBar(
            total: totalPayment,
            onPressed: vm.isLoading ? null : () => _submit(vm),
            isLoading: vm.isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _submit(OrderViewmodel vm) async {
    final useSaved = vm.useSavedAddress && vm.selectedDelivery != null;
    final name = useSaved
        ? vm.selectedDelivery!.name
        : _nameController.text.trim();
    final phone = useSaved
        ? vm.selectedDelivery!.phone
        : _phoneController.text.trim();
    final address = useSaved
        ? vm.selectedDelivery!.address
        : _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin nhận hàng")),
      );
      return;
    }

    // Thực hiện đặt hàng
    final result = await vm.submitOrder(
      name: name,
      phone: phone,
      address: address,
      note: _noteController.text.trim(),
      requiredNote: _requiredNote,
    );

    if (!mounted) return;

    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: ${vm.errorMessage}")));
      return;
    }

    final url = result?.paymentUrl;

    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go("/cart");
        }

        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không mở được link thanh toán")));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Đặt hàng thành công")));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go("/cart");
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LocationSelectors extends StatelessWidget {
  final OrderViewmodel vm;
  const _LocationSelectors({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Dropdown<GhnProvince>(
          label: "Tỉnh/Thành",
          value: vm.selectedProvince,
          items: vm.provinces,
          itemLabel: (p) => p.provinceName,
          onChanged: (value) => vm.selectProvince(value),
        ),
        _Dropdown<GhnDistrict>(
          label: "Quận/Huyện",
          value: vm.selectedDistrict,
          items: vm.districts,
          itemLabel: (d) => d.districtName,
          onChanged: (value) => vm.selectDistrict(value),
        ),
        _Dropdown<GhnWard>(
          label: "Phường/Xã",
          value: vm.selectedWard,
          items: vm.wards,
          itemLabel: (w) => w.wardName,
          onChanged: (value) => vm.selectWard(value),
        ),
      ],
    );
  }
}

class _NoteSection extends StatelessWidget {
  final TextEditingController noteController;
  final String requiredNote;
  final ValueChanged<String?> onRequiredNoteChanged;

  const _NoteSection({
    required this.noteController,
    required this.requiredNote,
    required this.onRequiredNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    // const options = [
    //   {"value": "KHONGCHOXEMHANG", "label": "Không cho xem hàng"},
    //   {"value": "CHOXEMHANGKHONGTHU", "label": "Cho xem hàng không thử"},
    //   {"value": "CHOTHUHANG", "label": "Cho thử hàng"},
    // ];
    return Column(
      children: [
        // _Dropdown<String>(
        //   label: "Yêu cầu giao hàng",
        //   value: requiredNote,
        //   items: options.map((e) => e["value"]!).toList(),
        //   itemLabel: (value) =>
        //       options.firstWhere((e) => e["value"] == value)["label"]!,
        //   onChanged: onRequiredNoteChanged,
        // ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: "Ghỉ chú",
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double total;
  final VoidCallback? onPressed;
  final bool isLoading;
  const _BottomBar({
    required this.total,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Tổng cộng"),
                  Text(
                    total.toVnd(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Đặt hàng"),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item, child: Text(itemLabel(item))),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
