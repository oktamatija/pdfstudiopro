import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import '../widgets/annotation_layer.dart';
import '../widgets/page_thumbnail_filmstrip.dart';
import '../widgets/share_export_modal.dart';
import '../widgets/tool_dock.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final TransformationController _transformController = TransformationController();

  // Inverted color filter for night reading mode
  static const ColorFilter _nightModeFilter = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  // Sepia warmth filter
  static const ColorFilter _sepiaFilter = ColorFilter.matrix(<double>[
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _openShareModal(BuildContext context, PdfProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareExportModal(
        onGenerateFinalPdf: () => provider.exportFinalPdf(),
        fileName: provider.fileName,
        totalPages: provider.totalPages,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PdfProvider>();
    final pageData = provider.currentPageData;
    final isDrawMode = provider.editorMode == EditorMode.draw ||
        provider.editorMode == EditorMode.highlight;

    return Scaffold(
      backgroundColor: provider.readingMode == ReadingMode.night
          ? const Color(0xFF121212)
          : (provider.readingMode == ReadingMode.sepia
              ? const Color(0xFFFBF0D9)
              : const Color(0xFFECEFF1)),
      appBar: provider.isFullscreen
          ? null
          : AppBar(
              titleSpacing: 0,
              elevation: 0.5,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Page ${provider.currentPageIndex + 1} of ${provider.totalPages}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              actions: [
                // Undo / Redo
                IconButton(
                  onPressed: provider.canUndo ? () => provider.undo() : null,
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: 'Undo',
                ),
                IconButton(
                  onPressed: provider.canRedo ? () => provider.redo() : null,
                  icon: const Icon(Icons.redo_rounded),
                  tooltip: 'Redo',
                ),
                // Reading mode cycle (Day / Night / Sepia)
                PopupMenuButton<ReadingMode>(
                  icon: Icon(
                    provider.readingMode == ReadingMode.night
                        ? Icons.dark_mode_rounded
                        : (provider.readingMode == ReadingMode.sepia
                            ? Icons.menu_book_rounded
                            : Icons.light_mode_rounded),
                  ),
                  tooltip: 'Reading theme',
                  onSelected: (m) => provider.setReadingMode(m),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: ReadingMode.normal,
                      child: Row(
                        children: [
                          Icon(Icons.light_mode, color: Colors.amber),
                          SizedBox(width: 8),
                          Text('Day (Normal)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: ReadingMode.night,
                      child: Row(
                        children: [
                          Icon(Icons.dark_mode, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text('Night (Inverted)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: ReadingMode.sepia,
                      child: Row(
                        children: [
                          Icon(Icons.auto_stories, color: Colors.brown),
                          SizedBox(width: 8),
                          Text('Sepia (Warm)'),
                        ],
                      ),
                    ),
                  ],
                ),
                // Export & Share
                IconButton.filledTonal(
                  onPressed: () => _openShareModal(context, provider),
                  icon: const Icon(Icons.share_rounded, color: Colors.blueAccent),
                  tooltip: 'Share & Export',
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: Stack(
        children: [
          // Main PDF Page Viewer & Canvas
          provider.isLoading && pageData == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        provider.statusMessage,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (pageData == null) {
                      return const Center(child: Text('No page data available.'));
                    }

                    // Fit page inside constraints
                    final double aspect = pageData.width / pageData.height;
                    double displayWidth = constraints.maxWidth - 24;
                    double displayHeight = displayWidth / aspect;

                    if (displayHeight > constraints.maxHeight - 140) {
                      displayHeight = constraints.maxHeight - 140;
                      displayWidth = displayHeight * aspect;
                    }

                    return InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.8,
                      maxScale: 4.0,
                      panEnabled: !isDrawMode, // Disable single touch pan in drawing mode
                      scaleEnabled: true,
                      child: Center(
                        child: Container(
                          width: displayWidth,
                          height: displayHeight,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                // 1. Base PDF Rendered Image (with reading mode filter)
                                Positioned.fill(
                                  child: ColorFiltered(
                                    colorFilter: provider.readingMode == ReadingMode.night
                                        ? _nightModeFilter
                                        : (provider.readingMode == ReadingMode.sepia
                                            ? _sepiaFilter
                                            : const ColorFilter.mode(
                                                Colors.transparent,
                                                BlendMode.multiply,
                                              )),
                                    child: Image.memory(
                                      pageData.imageBytes,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),

                                // 2. Interactive Annotation Layer (Signatures, Text, Shapes, Pen)
                                Positioned.fill(
                                  child: AnnotationLayer(
                                    pageWidth: displayWidth,
                                    pageHeight: displayHeight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // Previous Page Floating Chevron
          if (provider.currentPageIndex > 0 && !provider.isFullscreen)
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height * 0.45,
              child: FloatingActionButton.small(
                heroTag: 'prev_page',
                backgroundColor: Colors.black.withOpacity(0.6),
                foregroundColor: Colors.white,
                onPressed: () => provider.previousPage(),
                child: const Icon(Icons.chevron_left_rounded),
              ),
            ),

          // Next Page Floating Chevron
          if (provider.currentPageIndex < provider.totalPages - 1 && !provider.isFullscreen)
            Positioned(
              right: 12,
              top: MediaQuery.of(context).size.height * 0.45,
              child: FloatingActionButton.small(
                heroTag: 'next_page',
                backgroundColor: Colors.black.withOpacity(0.6),
                foregroundColor: Colors.white,
                onPressed: () => provider.nextPage(),
                child: const Icon(Icons.chevron_right_rounded),
              ),
            ),

          // Fullscreen toggle button
          Positioned(
            top: 12,
            right: 12,
            child: IconButton.filledTonal(
              onPressed: () => provider.toggleFullscreen(),
              icon: Icon(
                provider.isFullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
              ),
              tooltip: provider.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      bottomNavigationBar: provider.isFullscreen
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PageThumbnailFilmstrip(),
                const ToolDock(),
              ],
            ),
    );
  }
}
