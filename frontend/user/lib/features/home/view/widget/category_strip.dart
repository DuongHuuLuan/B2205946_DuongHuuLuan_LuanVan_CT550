import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/widget/arrow_button.dart';

class CategoryStrip extends StatefulWidget {
  final List<Category> categories;
  final Map<int, String> thumbnails; // categoryId -> imageUrl
  final void Function(Category c)? onTap;

  const CategoryStrip({
    super.key,
    required this.categories,
    required this.thumbnails,
    this.onTap,
  });

  @override
  State<CategoryStrip> createState() => _CategoryStripState();
}

class _CategoryStripState extends State<CategoryStrip> {
  final ScrollController _controller = ScrollController();

  bool _showLeft = false;
  bool _showRight = false;

  void _updateArrows() {
    if (!_controller.hasClients) return;

    final max = _controller.position.maxScrollExtent;
    final offset = _controller.offset;

    final canScroll = max > 0;
    final showLeftNow = canScroll && offset > 2;
    final showRightNow = canScroll && offset < max - 2;

    if (showLeftNow != _showLeft || showRightNow != _showRight) {
      setState(() {
        _showLeft = showLeftNow;
        _showRight = showRightNow;
      });
    }
  }

  void _scrollBy(double dx) {
    if (!_controller.hasClients) return;

    final minE = _controller.position.minScrollExtent;
    final maxE = _controller.position.maxScrollExtent;

    final target = (_controller.offset + dx).clamp(minE, maxE);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void didUpdateWidget(covariant CategoryStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    return Container(
      // color: const Color(0xFF070C14),
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: widget.categories.map((c) {
                  final thumb = widget.thumbnails[c.id];

                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => widget.onTap?.call(c),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: (thumb != null && thumb.isNotEmpty)
                                  ? Image.network(thumb, fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.black38,
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.secondary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            child: Text(
                              c.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Left arrow (fade)
            Positioned(
              left: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: IgnorePointer(
                  ignoring: !_showLeft,
                  child: AnimatedOpacity(
                    opacity: _showLeft ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: ArrowButton(
                      icon: Icons.chevron_left,
                      onTap: () => _scrollBy(-220),
                    ),
                  ),
                ),
              ),
            ),

            // Right arrow (fade)
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: IgnorePointer(
                  ignoring: !_showRight,
                  child: AnimatedOpacity(
                    opacity: _showRight ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: ArrowButton(
                      icon: Icons.chevron_right,
                      onTap: () => _scrollBy(220),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

