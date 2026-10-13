import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/annotation_model.dart';
import '../providers/pdf_provider.dart';
import 'saved_signatures_sheet.dart';
import 'signature_modal.dart';

class ToolDock extends StatelessWidget {
  const ToolDock({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PdfProvider>();
    final mode = provider.editorMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contextual Sub-bar (shows colors, shapes, stamps, or sign options based on active mode)
        if (mode != EditorMode.read)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSubBarContent(context, provider),
          ),

        // Main Bottom Dock
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModeButton(
                  context: context,
                  icon: Icons.menu_book_rounded,
                  label: 'Read',
                  isSelected: mode == EditorMode.read,
                  onTap: () => provider.setEditorMode(EditorMode.read),
                ),
                _buildModeButton(
                  context: context,
                  icon: Icons.draw_rounded,
                  label: 'Sign',
                  isSelected: mode == EditorMode.sign,
                  badge: 'Pro',
                  onTap: () => provider.setEditorMode(EditorMode.sign),
                ),
                _buildModeButton(
                  context: context,
                  icon: Icons.edit_rounded,
                  label: 'Pen',
                  isSelected: mode == EditorMode.draw,
                  onTap: () => provider.setEditorMode(EditorMode.draw),
                ),
                _buildModeButton(
                  context: context,
                  icon: Icons.brush_rounded,
                  label: 'Highlight',
                  isSelected: mode == EditorMode.highlight,
                  onTap: () => provider.setEditorMode(EditorMode.highlight),
                ),
                _buildModeButton(
                  context: context,
                  icon: Icons.text_fields_rounded,
                  label: 'Text',
                  isSelected: mode == EditorMode.text,
                  onTap: () => provider.setEditorMode(EditorMode.text),
                ),
                _buildModeButton(
                  context: context,
                  icon: Icons.category_rounded,
                  label: 'Shapes',
                  isSelected: mode == EditorMode.shape,
                  onTap: () => provider.setEditorMode(EditorMode.shape),
                ),
                _buildModeButton(
                  context: context,
                  icon: Icons.approval_rounded,
                  label: 'Stamps',
                  isSelected: mode == EditorMode.stamp,
                  onTap: () => provider.setEditorMode(EditorMode.stamp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
                ),
                if (badge != null)
                  Positioned(
                    right: -10,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubBarContent(BuildContext context, PdfProvider provider) {
    switch (provider.editorMode) {
      case EditorMode.sign:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openSignatureDialog(context, provider),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Draw Signature'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _openSavedSignaturesSheet(context, provider),
              icon: const Icon(Icons.folder_shared_rounded, size: 18),
              label: const Text('My Vault'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
                provider.placeTextBox('Date: $dateStr');
              },
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text('Date Stamp'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        );

      case EditorMode.draw:
      case EditorMode.highlight:
        final isHighlight = provider.editorMode == EditorMode.highlight;
        final colors = isHighlight
            ? [
                const Color(0xFFFFEB3B), // Neon Yellow
                const Color(0xFF69F0AE), // Neon Green
                const Color(0xFF40C4FF), // Neon Blue
                const Color(0xFFFF80AB), // Pink
                const Color(0xFFFFD180), // Orange
              ]
            : [
                const Color(0xFF1565C0), // Blue
                const Color(0xFF1A1A1A), // Black
                const Color(0xFFC62828), // Red
                const Color(0xFF2E7D32), // Green
                const Color(0xFF6A1B9A), // Purple
              ];

        return Row(
          children: [
            Text(
              isHighlight ? 'Highlight:' : 'Pen Ink:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Row(
              children: colors.map((c) {
                final isSelected = provider.penColor.value == c.value;
                return GestureDetector(
                  onTap: () => provider.setPenColor(c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Text(
              'Size: ${provider.strokeWidth.toInt()}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Slider(
              value: provider.strokeWidth,
              min: 1.0,
              max: 8.0,
              divisions: 7,
              onChanged: (v) => provider.setStrokeWidth(v),
            ),
          ],
        );

      case EditorMode.text:
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _promptAddText(context, provider),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Text Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Spacer(),
            const Text('Size: ', style: TextStyle(fontSize: 12)),
            DropdownButton<double>(
              value: provider.fontSize,
              items: const [
                DropdownMenuItem(value: 12.0, child: Text('Small (12)')),
                DropdownMenuItem(value: 16.0, child: Text('Medium (16)')),
                DropdownMenuItem(value: 22.0, child: Text('Large (22)')),
                DropdownMenuItem(value: 28.0, child: Text('Heading (28)')),
              ],
              onChanged: (v) {
                if (v != null) provider.setFontSize(v);
              },
            ),
          ],
        );

      case EditorMode.shape:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickShape(
              icon: Icons.check_circle_outline,
              label: 'Checkmark',
              onTap: () => provider.placeShape(ShapeType.checkmark),
            ),
            _buildQuickShape(
              icon: Icons.highlight_off_rounded,
              label: 'Cross',
              onTap: () => provider.placeShape(ShapeType.cross),
            ),
            _buildQuickShape(
              icon: Icons.crop_square_rounded,
              label: 'Rectangle',
              onTap: () => provider.placeShape(ShapeType.rectangle),
            ),
            _buildQuickShape(
              icon: Icons.circle_outlined,
              label: 'Circle',
              onTap: () => provider.placeShape(ShapeType.circle),
            ),
            _buildQuickShape(
              icon: Icons.block_rounded,
              label: 'Redact',
              onTap: () => provider.placeShape(ShapeType.redaction),
            ),
          ],
        );

      case EditorMode.stamp:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickStamp('APPROVED', Colors.green, () => provider.placeStamp(StampType.approved)),
              _buildQuickStamp('CONFIDENTIAL', Colors.red, () => provider.placeStamp(StampType.confidential)),
              _buildQuickStamp('PAID', Colors.blue, () => provider.placeStamp(StampType.paid)),
              _buildQuickStamp('DRAFT', Colors.orange, () => provider.placeStamp(StampType.draft)),
              _buildQuickStamp('FINAL', Colors.purple, () => provider.placeStamp(StampType.finalVersion)),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuickShape({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.blueAccent),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStamp(String title, MaterialColor color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(title, style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
        backgroundColor: color.shade50,
        side: BorderSide(color: color.shade400),
        onPressed: onTap,
      ),
    );
  }

  void _openSignatureDialog(BuildContext context, PdfProvider provider) {
    showDialog(
      context: context,
      builder: (_) => SignatureModal(
        onSignatureAdopted: (bytes) {
          provider.placeSignature(bytes);
        },
      ),
    );
  }

  void _openSavedSignaturesSheet(BuildContext context, PdfProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SavedSignaturesSheet(
        onSelectSignature: (bytes) {
          provider.placeSignature(bytes);
        },
        onAddNewSignature: () => _openSignatureDialog(context, provider),
      ),
    );
  }

  void _promptAddText(BuildContext context, PdfProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Text Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter note or comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.placeTextBox(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Place Note'),
          ),
        ],
      ),
    );
  }
}
