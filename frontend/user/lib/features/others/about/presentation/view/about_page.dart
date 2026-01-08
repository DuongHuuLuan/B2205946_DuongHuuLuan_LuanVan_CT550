import 'package:b2205946_duonghuuluan_luanvan/app/theme/text_styles.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/home_app_bar.dart';
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
    return Scaffold(
      key: _scaffoldState,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("ROYAL PREMIUM HELMETS", style: AppTextStyles.bodyLarge),
              const SizedBox(height: 20),
              Text(
                "Được nghiên cứu, thiết kế và sản xuất bởi công ty MAFA, một công ty chuyên sản xuất mũ bảo hiểm chất lượng cao, an toàn và chiếm lĩnh thị trường hàng đầu tại Việt Nam. Công ty MAFA là công ty con thuộc sở hữu và quản lý của Tập đoàn Quốc tế Châu Á.",
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
