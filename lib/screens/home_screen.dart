import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pdf_doc_item.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_intent_service.dart';
import '../services/storage_service.dart';
import '../widgets/saved_signatures_sheet.dart';
import '../widgets/signature_modal.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PdfDocItem> _recentFiles = [];
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _initIncomingPdfHandler();
  }

  void _initIncomingPdfHandler() {
    // 1. Cold launch: Check if launched with a PDF directly from WhatsApp / Email
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialDoc = await PdfIntentService.getInitialPdf();
      if (initialDoc != null && mounted) {
        _openIncomingPdf(initialDoc);
      }
    });

    // 2. Warm launch: Listen for incoming PDF while app is in background or foreground
    PdfIntentService.setPdfOpenedListener((doc) {
      if (mounted) {
        _openIncomingPdf(doc);
      }
    });
  }

  Future<void> _openIncomingPdf(IncomingPdfDocument doc) async {
    final nav = Navigator.of(context);
    final provider = context.read<PdfProvider>();
    await provider.loadPdf(
      bytes: doc.bytes,
      name: doc.name,
      path: doc.path,
    );
    _loadRecent();
    if (!mounted) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const PdfViewerScreen()),
    );
  }

  Future<void> _loadRecent() async {
    final list = await StorageService.loadRecentFiles();
    setState(() {
      _recentFiles = list;
      _loadingRecent = false;
    });
  }

  Future<void> _pickAndOpenFile(BuildContext context) async {
    final nav = Navigator.of(context);
    final provider = context.read<PdfProvider>();
    final file = await StorageService.pickPdfFile();
    if (file != null) {
      final bytes = await file.readAsBytes();

      if (mounted) {
        await provider.loadPdf(
          bytes: bytes,
          name: file.name,
          path: file.path,
        );
        _loadRecent();

        if (mounted) {
          nav.push(
            MaterialPageRoute(builder: (_) => const PdfViewerScreen()),
          );
        }
      }
    }
  }

  Future<void> _openSampleNda(BuildContext context) async {
    final nav = Navigator.of(context);
    final provider = context.read<PdfProvider>();
    await provider.loadSampleNda();
    _loadRecent();

    if (!mounted) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const PdfViewerScreen()),
    );
  }

  Future<void> _openSampleInvoice(BuildContext context) async {
    final nav = Navigator.of(context);
    final provider = context.read<PdfProvider>();
    await provider.loadSampleInvoice();
    _loadRecent();

    if (!mounted) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const PdfViewerScreen()),
    );
  }

  Future<void> _openRecentFile(BuildContext context, PdfDocItem item) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PdfProvider>();

    if (item.isSample) {
      if (item.name.contains('NDA')) {
        _openSampleNda(context);
      } else {
        _openSampleInvoice(context);
      }
      return;
    }

    if (item.path != null) {
      final file = File(item.path!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        await provider.loadPdf(
          bytes: bytes,
          name: item.name,
          path: item.path,
        );
        if (!mounted) return;
        nav.push(
          MaterialPageRoute(builder: (_) => const PdfViewerScreen()),
        );
        return;
      }
    }

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('File not found on device storage.')),
    );
  }

  void _openSignatureVault(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SavedSignaturesSheet(
        onSelectSignature: (_) {},
        onAddNewSignature: () {
          showDialog(
            context: context,
            builder: (_) => SignatureModal(onSignatureAdopted: (_) {}),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text(
              'PDF Studio Pro',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openSignatureVault(context),
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Signature Vault',
          ),
          IconButton(
            onPressed: () => _showAboutDialog(context),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Action Banner
              _buildHeroBanner(context),
              const SizedBox(height: 24),

              // Feature Highlights Row
              _buildFeaturesRow(context),
              const SizedBox(height: 24),

              // Sample Documents Section
              const Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ready-to-Sign Sample Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSampleDocs(context),
              const SizedBox(height: 24),

              // Recent Files Section
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentFilesList(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAndOpenFile(context),
        icon: const Icon(Icons.file_open_rounded),
        label: const Text('Open PDF'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'All-in-One Android PDF Suite',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.share_rounded, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Read, Sign, Edit & Share\nAny PDF Document',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Export vector crisp PDFs and share directly to WhatsApp, WhatsApp Business, Email, and Nearby Devices.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickAndOpenFile(context),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Pick PDF File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _openSignatureVault(context),
                icon: const Icon(Icons.draw_rounded, size: 18, color: Colors.white),
                label: const Text('Signature Vault', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniFeatureCard(
            icon: Icons.menu_book_rounded,
            title: 'Reader Mode',
            subtitle: 'Day / Night / Sepia',
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniFeatureCard(
            icon: Icons.draw_rounded,
            title: 'Digital Sign',
            subtitle: 'Stylus & Finger',
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMiniFeatureCard(
            icon: Icons.share_rounded,
            title: 'Quick Share',
            subtitle: 'WA / Mail / Beam',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleDocs(BuildContext context) {
    return Column(
      children: [
        // NDA Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openSampleNda(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handshake_rounded, color: Colors.blueAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Mutual Non-Disclosure Agreement',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Ready to Sign',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '2 pages • Standard legal contract with signature & date fields.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Invoice Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openSampleInvoice(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Commercial Service Invoice',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Stamp & Pay',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1 page • B2B invoice with approval stamp & sign zone.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFilesList(BuildContext context) {
    if (_loadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentFiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No recent documents yet',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Open a sample document or pick a file from device storage.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentFiles.map((item) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              '${item.pageCount} pages • ${item.formattedSize} • ${DateFormat('MMM d, h:mm a').format(item.modifiedDate)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => _openRecentFile(context, item),
          ),
        );
      }).toList(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('PDF Studio Pro'),
          ],
        ),
        content: const Text(
          'A powerful Android PDF Suite for reading, digitally signing, annotating, and sharing PDF files.\n\n'
          '• Digital Signature Studio (Finger / Stylus & Saved Presets)\n'
          '• Full Freehand Pen, Highlighter & Shape Markups\n'
          '• Pre-built Professional Stamps (APPROVED, PAID, CONFIDENTIAL)\n'
          '• Seamless Sharing to WhatsApp, WhatsApp Business, Gmail, and Nearby Share / PC\n'
          '• Inverted Night Reading & Sepia Tone Reading Modes',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
