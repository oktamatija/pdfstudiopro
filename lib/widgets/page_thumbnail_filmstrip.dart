import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';

class PageThumbnailFilmstrip extends StatelessWidget {
  const PageThumbnailFilmstrip({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PdfProvider>();
    final total = provider.totalPages;
    final current = provider.currentPageIndex;

    if (total <= 1) return const SizedBox.shrink();

    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: total,
          itemBuilder: (ctx, i) {
            final isSelected = i == current;
            return GestureDetector(
              onTap: () => provider.setCurrentPage(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                width: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 6)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 24,
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'P. ${i + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blueAccent : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
