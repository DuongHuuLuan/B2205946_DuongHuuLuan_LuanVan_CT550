import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/viewmodel/evaluate_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/widget/evaluate_history_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileReviewsPage extends StatelessWidget {
  const ProfileReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        title: const Text("Lịch sử đánh giá"),
        actions: [
          IconButton(
            tooltip: "Làm mới",
            onPressed: () => context.read<EvaluateViewmodel>().refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: EvaluateHistorySection(),
        ),
      ),
    );
  }
}
