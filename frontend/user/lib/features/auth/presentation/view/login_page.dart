import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/login_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';

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

    // Lấy Theme từ context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Đồng bộ màu nền
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Sử dụng TextTheme thay cho AppTextStyles.displayLarge
              Text(
                "Đăng nhập",
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme
                            .surfaceVariant, // Thay AppColors.surface2
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ), // Thay AppColors.border
                      ),
                      child: Image.asset('assets/images/logo.webp'),
                    ),
                    const SizedBox(height: 25),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(
                          Icons.email,
                          color: colorScheme.onPrimary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Vui lòng nhập email";
                        if (!value.contains("@")) return "Email không hợp lệ";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu",
                        prefixIcon: Icon(
                          Icons.lock,
                          color: colorScheme.onPrimary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Vui lòng nhập mật khẩu";
                        if (value.length < 6) return "Mật khẩu phải từ 6 ký tự";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    if (loginViewModel.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          loginViewModel.errorMessage,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 14,
                          ),
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
                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   const SnackBar(
                                  //     content: Text("Đăng nhập thành công"),
                                  //   ),
                                  // );
                                  context.go('/');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary, // Màu nút chính
                        foregroundColor:
                            colorScheme.onPrimary, // Màu chữ trên nút
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: loginViewModel.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              "GO!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton(
                      onPressed: () => context.go("/register"),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.onPrimary),
                        foregroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          "TẠO TÀI KHOẢN",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
