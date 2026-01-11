import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _scaffoldState = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // 1. Truy xuất bộ màu và bộ font từ Theme hệ thống
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      key: _scaffoldState,
      // Đảm bảo nền của Scaffold đi theo màu nền của Theme
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24), // Tăng padding một chút cho thoáng
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2. Sử dụng tiêu đề lớn từ Theme
              Text(
                "ROYAL PREMIUM HELMETS",
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Được nghiên cứu, thiết kế và sản xuất bởi công ty MAFA, một công ty chuyên sản xuất mũ bảo hiểm chất lượng cao, an toàn và chiếm lĩnh thị trường hàng đầu tại Việt Nam. Công ty MAFA là công ty con thuộc sở hữu và quản lý của Tập đoàn Quốc tế Châu Á.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
