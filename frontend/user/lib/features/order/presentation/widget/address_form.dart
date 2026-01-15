import 'package:flutter/material.dart';

class AddressForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  const AddressForm({
    super.key,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextField(controller: nameController, label: "Họ tên"),
        _TextField(controller: phoneController, label: "Số điện thoại"),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _TextField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
