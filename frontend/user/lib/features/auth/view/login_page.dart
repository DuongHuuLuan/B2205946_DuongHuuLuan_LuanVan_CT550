import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/login_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/auth_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.watch<LoginViewModel>();
    final authState = context.read<AuthViewmodel>();
    return Scaffold(
      appBar: AppBar(title: Text("Đăng nhập")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  "Chào mừng trở lại",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Vui lòng nhập email";
                    if (!value.contains("@")) return "Email không hợp lệ";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true, // ẩn mật khẩu
                  decoration: const InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Vui lòng nhập mật khẩu";
                    if (value.length < 6) return "Mật khẩu phải từ 6 ký tự";
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // hiển thị thông báo lỗi nếu có từ ViewModel
                if (loginViewModel.errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      loginViewModel.errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: loginViewModel.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final success = await loginViewModel.login(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                              authState,
                            );
                            if (success == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Đăng nhập thành công"),
                                ),
                              );
                              context.go('/');
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: loginViewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Đăng nhập",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    context.go("/register");
                  },
                  child: Text("Chưa có tài khoản? Đăng ký ngay"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
