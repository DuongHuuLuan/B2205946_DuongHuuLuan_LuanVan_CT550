import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';

class ProfileEditValue {
  final String name;
  final String phone;
  final String gender;
  final DateTime? birthday;
  final String avatar;

  const ProfileEditValue({
    required this.name,
    required this.phone,
    required this.gender,
    required this.birthday,
    required this.avatar,
  });
}

class ProfileEditDialog extends StatefulWidget {
  final Profile? profile;
  final String fallbackName;
  final bool isSubmitting;

  const ProfileEditDialog({
    super.key,
    required this.profile,
    required this.fallbackName,
    required this.isSubmitting,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  DateTime? _birthday;
  String _gender = "";

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(
      text: (p?.name ?? widget.fallbackName).trim(),
    );
    _phoneController = TextEditingController(text: (p?.phone ?? "").trim());
    _avatarController = TextEditingController(text: (p?.avatar ?? "").trim());
    _birthday = p?.birthday;
    final rawGender = (p?.gender ?? "").trim().toLowerCase();
    _gender = _isValidGender(rawGender) ? rawGender : "";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final birthdayText = _birthday == null ? "" : _formatDateLabel(_birthday!);

    return AlertDialog(
      title: const Text("Chỉnh sửa thông tin cá nhân"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Họ và tên",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = (value ?? "").trim();
                  if (text.length > 50) {
                    return "Tên tối đa 50 ký tự";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Số điện thoại",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = (value ?? "").trim();
                  if (text.isEmpty) return null;
                  final phonePattern = RegExp(r"^\+?1?\d{9,15}$");
                  if (!phonePattern.hasMatch(text)) {
                    return "Số điện thoại không hợp lệ";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                items: const [
                  DropdownMenuItem(value: "", child: Text("Không chọn")),
                  DropdownMenuItem(value: "male", child: Text("Nam")),
                  DropdownMenuItem(value: "female", child: Text("Nữ")),
                  DropdownMenuItem(value: "other", child: Text("Khác")),
                ],
                onChanged: widget.isSubmitting
                    ? null
                    : (value) => setState(() => _gender = value ?? ""),
                decoration: const InputDecoration(
                  labelText: "Giới tính",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: widget.isSubmitting ? null : _pickBirthday,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Ngày sinh",
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Chọn ngày",
                          onPressed: widget.isSubmitting ? null : _pickBirthday,
                          icon: const Icon(Icons.calendar_today_outlined),
                        ),
                        IconButton(
                          tooltip: "Xóa ngày sinh",
                          onPressed: widget.isSubmitting
                              ? null
                              : () => setState(() => _birthday = null),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      birthdayText.isEmpty
                          ? "Chưa chọn ngày sinh"
                          : birthdayText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Avatar URL",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Lưu"),
        ),
      ],
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate =
        _birthday ?? DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(1900, 1, 1);
    final lastDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;
    setState(() => _birthday = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ProfileEditValue(
        name: _nameController.text,
        phone: _phoneController.text,
        gender: _gender,
        birthday: _birthday,
        avatar: _avatarController.text,
      ),
    );
  }

  String _formatDateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, "0");
    final month = value.month.toString().padLeft(2, "0");
    final year = value.year.toString();
    return "$day/$month/$year";
  }

  bool _isValidGender(String value) {
    return value == "male" || value == "female" || value == "other";
  }
}
