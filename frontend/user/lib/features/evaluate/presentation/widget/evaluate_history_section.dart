import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/viewmodel/evaluate_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EvaluateHistorySection extends StatefulWidget {
  const EvaluateHistorySection({super.key});

  @override
  State<EvaluateHistorySection> createState() => _EvaluateHistorySectionState();
}

class _EvaluateHistorySectionState extends State<EvaluateHistorySection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<EvaluateViewmodel>().load(perPage: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EvaluateViewmodel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.evaluates.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.errorMessage != null && vm.evaluates.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: vm.isRefreshing ? null : vm.refresh,
                  child: const Text("Thử lại"),
                ),
              ],
            ),
          );
        }

        if (vm.evaluates.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("Bạn chưa có đánh giá nào."),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.evaluates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final evaluate = vm.evaluates[index];
                return _EvaluateCard(evaluate: evaluate);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: vm.isRefreshing ? null : vm.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Làm mới"),
                  ),
                ),
                if (vm.hasNextPage) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: vm.isLoadingMore ? null : vm.loadMore,
                      child: Text(
                        vm.isLoadingMore ? "Đang tải..." : "Xem thêm",
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _EvaluateCard extends StatelessWidget {
  final EvaluateItem evaluate;
  const _EvaluateCard({required this.evaluate});

  @override
  Widget build(BuildContext context) {
    final content = (evaluate.content ?? "").trim();
    final adminReply = (evaluate.adminReply ?? "").trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "#RV-${evaluate.id}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  "Đơn #DH-${evaluate.orderId}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                _StarBadge(rate: evaluate.rate),
              ],
            ),
            const SizedBox(height: 8),
            Text(content.isEmpty ? "(Không có nội dung)" : content),
            if (evaluate.images.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: evaluate.images
                    .map(
                      (img) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _resolveUrl(img.imageUrl),
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 68,
                            height: 68,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            if (adminReply.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Phản hồi từ shop",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(adminReply),
                  ],
                ),
              )
            else
              Text(
                "Chưa có phản hồi từ shop.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _resolveUrl(String raw) {
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    final base = AppConstants.baseUrl.replaceAll(RegExp(r"/+$"), "");
    return "$base${raw.startsWith("/") ? "" : "/"}$raw";
  }
}

class _StarBadge extends StatelessWidget {
  final int rate;
  const _StarBadge({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text("⭐ $rate/5"),
    );
  }
}
