import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';

class ShareExportModal extends StatefulWidget {
  final Future<Uint8List> Function() onGenerateFinalPdf;
  final String fileName;
  final int totalPages;

  const ShareExportModal({
    super.key,
    required this.onGenerateFinalPdf,
    required this.fileName,
    required this.totalPages,
  });

  @override
  State<ShareExportModal> createState() => _ShareExportModalState();
}

class _ShareExportModalState extends State<ShareExportModal> {
  bool _isProcessing = false;
  String _statusMessage = '';

  Future<Uint8List?> _getPdfBytes() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Rendering high-resolution PDF...';
    });

    try {
      final bytes = await widget.onGenerateFinalPdf();
      setState(() => _isProcessing = false);
      return bytes;
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _handleSaveToDevice() async {
    final bytes = await _getPdfBytes();
    if (bytes == null) return;

    final path = await StorageService.savePdfToDevice(bytes, widget.fileName);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved successfully to:\n$path'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleWhatsAppShare({bool isBusiness = false}) async {
    final bytes = await _getPdfBytes();
    if (bytes == null) return;

    if (mounted) Navigator.pop(context);
    await ShareService.shareToWhatsApp(
      pdfBytes: bytes,
      fileName: widget.fileName,
      isBusiness: isBusiness,
    );
  }

  Future<void> _handleEmailShare() async {
    final bytes = await _getPdfBytes();
    if (bytes == null) return;

    if (mounted) Navigator.pop(context);
    await ShareService.shareViaEmail(
      pdfBytes: bytes,
      fileName: widget.fileName,
      subject: 'Signed PDF: ${widget.fileName}',
    );
  }

  Future<void> _handleNearbyShare() async {
    final bytes = await _getPdfBytes();
    if (bytes == null) return;

    if (mounted) Navigator.pop(context);
    await ShareService.shareToOtherDevices(
      pdfBytes: bytes,
      fileName: widget.fileName,
    );
  }

  Future<void> _handlePrint() async {
    final bytes = await _getPdfBytes();
    if (bytes == null) return;

    if (mounted) Navigator.pop(context);
    await ShareService.printDocument(
      pdfBytes: bytes,
      documentName: widget.fileName,
    );
  }

  Future<void> _handleUniversalShare() async {
    final bytes = await _getPdfBytes();
    if (bytes == null) return;

    if (mounted) Navigator.pop(context);
    await ShareService.shareDocument(
      pdfBytes: bytes,
      fileName: widget.fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.share_rounded, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export & Share PDF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.fileName} (${widget.totalPages} pages)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else ...[
            // Share Targets Grid
            Row(
              children: [
                Expanded(
                  child: _buildShareCard(
                    title: 'WhatsApp',
                    subtitle: 'Direct Chat',
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF25D366), // WhatsApp Green
                    onTap: () => _handleWhatsAppShare(isBusiness: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShareCard(
                    title: 'WA Business',
                    subtitle: 'Business Chat',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFF128C7E), // WhatsApp Business Teal
                    onTap: () => _handleWhatsAppShare(isBusiness: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildShareCard(
                    title: 'Email / Gmail',
                    subtitle: 'Attach Document',
                    icon: Icons.mail_rounded,
                    color: const Color(0xFFEA4335), // Gmail Red
                    onTap: _handleEmailShare,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShareCard(
                    title: 'Other Devices',
                    subtitle: 'Quick / Nearby Share',
                    icon: Icons.devices_rounded,
                    color: const Color(0xFF673AB7), // Deep Purple
                    onTap: _handleNearbyShare,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildShareCard(
                    title: 'Save to Device',
                    subtitle: 'Downloads folder',
                    icon: Icons.save_alt_rounded,
                    color: const Color(0xFF1976D2), // Blue
                    onTap: _handleSaveToDevice,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShareCard(
                    title: 'Direct Print',
                    subtitle: 'WiFi / Bluetooth',
                    icon: Icons.print_rounded,
                    color: const Color(0xFF455A64), // Blue Grey
                    onTap: _handlePrint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _handleUniversalShare,
              icon: const Icon(Icons.more_horiz_rounded),
              label: const Text('Open System Sharesheet (More Apps)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildShareCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
