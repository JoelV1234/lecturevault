import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class SlideViewer extends StatelessWidget {
  final String filePath;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final bool showControls;

  const SlideViewer({
    super.key,
    required this.filePath,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Slide display
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: PdfViewer.file(filePath, params: const PdfViewerParams()),
          ),
        ),
        if (showControls) ...[
          const SizedBox(height: 10),
          // Page navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed:
                      currentPage > 0
                          ? () => onPageChanged(currentPage - 1)
                          : null,
                  iconSize: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Slide ${currentPage + 1} / $totalPages',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed:
                      currentPage < totalPages - 1
                          ? () => onPageChanged(currentPage + 1)
                          : null,
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
