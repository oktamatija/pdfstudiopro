import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_signature.dart';
import '../services/storage_service.dart';

class SignatureModal extends StatefulWidget {
  final void Function(Uint8List signatureBytes) onSignatureAdopted;

  const SignatureModal({
    super.key,
    required this.onSignatureAdopted,
  });

  @override
  State<SignatureModal> createState() => _SignatureModalState();
}

class _SignatureModalState extends State<SignatureModal> {
  late SignatureController _controller;
  Color _penColor = const Color(0xFF0D47A1); // Deep Navy Blue
  double _strokeWidth = 3.5;
  bool _saveToVault = true;
  final TextEditingController _titleController =
      TextEditingController(text: 'My Signature');

  final List<Color> _availableColors = [
    const Color(0xFF0D47A1), // Navy Blue
    const Color(0xFF1A1A1A), // Deep Black
    const Color(0xFFB71C1C), // Crimson Red
    const Color(0xFF1B5E20), // Forest Green
  ];

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _penColor,
      exportBackgroundColor: Colors.transparent,
    );
  }

  void _updateController() {
    final points = _controller.points;
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _penColor,
      exportBackgroundColor: Colors.transparent,
      points: points,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleAdopt() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw your signature before adopting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Uint8List? bytes = await _controller.toPngBytes();
    if (bytes != null && bytes.isNotEmpty) {
      if (_saveToVault) {
        final title = _titleController.text.trim().isEmpty
            ? 'My Signature'
            : _titleController.text.trim();
        await StorageService.saveSignature(
          SavedSignature(
            id: const Uuid().v4(),
            title: title,
            imageBytes: bytes,
            createdAt: DateTime.now(),
          ),
        );
      }

      widget.onSignatureAdopted(bytes);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: pwBetween(context),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.draw_rounded, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Digital Signature',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Sign with your finger or stylus',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Controls Bar (Pen Color & Thickness)
            Row(
              children: [
                // Color Palettes
                Row(
                  children: _availableColors.map((color) {
                    final isSelected = _penColor == color;
                    return GestureDetector(
                      onTap: () {
                        _penColor = color;
                        _updateController();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.white,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                // Stroke size selector
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 2.0, label: Text('Fine')),
                    ButtonSegment(value: 3.5, label: Text('Med')),
                    ButtonSegment(value: 5.5, label: Text('Bold')),
                  ],
                  selected: {_strokeWidth},
                  onSelectionChanged: (set) {
                    _strokeWidth = set.first;
                    _updateController();
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Drawing Canvas Area
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Guide Line
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 45,
                      child: Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const Positioned(
                      left: 24,
                      bottom: 24,
                      child: Text(
                        'Sign on the line above',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                    // Canvas
                    Signature(
                      controller: _controller,
                      backgroundColor: Colors.transparent,
                    ),
                    // Clear / Undo buttons overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () {
                              _controller.undo();
                              setState(() {});
                            },
                            icon: const Icon(Icons.undo, size: 18),
                            tooltip: 'Undo stroke',
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: 'Clear',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Save to Vault option
            Row(
              children: [
                Checkbox(
                  value: _saveToVault,
                  onChanged: (v) => setState(() => _saveToVault = v ?? true),
                ),
                const Text('Save to my signature presets', style: TextStyle(fontSize: 13)),
              ],
            ),
            if (_saveToVault)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 8, bottom: 8),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintText: 'Signature Title (e.g., Full Name, Formal)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleAdopt,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Adopt & Sign'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MainAxisAlignment pwBetween(BuildContext context) => MainAxisAlignment.spaceBetween;
}
