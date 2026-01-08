import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.secondary),
              height: 120,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      "assets/images/logo.webp",
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DrawerItem(
              title: "Về Chúng tôi",
              onTap: () {
                Navigator.pop(context);
                context.go("/about");
              },
            ),

            _DrawerItem(
              title: "Sản Phẩm",
              onTap: () {
                Navigator.pop(context);
                context.go("/products/categories");
              },
              trailing: const Icon(Icons.chevron_right, color: Colors.black),
            ),

            _DrawerItem(
              title: "Tin Tức",
              onTap: () {},
              trailing: const Icon(Icons.chevron_right, color: Colors.black),
            ),

            _DrawerItem(title: "Liên Hệ", onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  const _DrawerItem({required this.title, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
