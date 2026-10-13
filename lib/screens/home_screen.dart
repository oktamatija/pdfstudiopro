import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pdf_doc_item.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_intent_service.dart';
import '../services/share_service.dart';
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
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.deepOrangeAccent],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Studio Pro',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Read • Sign • Edit • WhatsApp Direct',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openSignatureVault(context),
            icon: const Icon(Icons.draw_rounded),
            tooltip: 'Signature Vault',
          ),
          IconButton(
            onPressed: () => _showAboutDialog(context),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About & Play Store',
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
              // 1. WhatsApp & System Direct-Open Live Status Banner
              _buildWhatsAppStatusBanner(context),
              const SizedBox(height: 16),

              // 2. Quick Action Hub (4 Primary Tools)
              _buildActionHub(context),
              const SizedBox(height: 24),

              // 3. Recent Documents (Prioritized immediately below Quick Actions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Recent Documents',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_recentFiles.isNotEmpty)
                    Text(
                      '${_recentFiles.length} files',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentFilesList(context),
              const SizedBox(height: 24),

              // 4. Ready-to-Sign Templates Section
              const Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Document Templates & Samples',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSampleDocs(context),
              const SizedBox(height: 36),
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

  Widget _buildWhatsAppStatusBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF25D366),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_chat_read_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp & WhatsApp Business Integration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E7E34)),
                ),
                Text(
                  'Tap any received PDF in WhatsApp to read & sign instantly.',
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 18),
        ],
      ),
    );
  }

  Widget _buildActionHub(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        // 1. Open PDF
        _buildHubCard(
          title: 'Open PDF',
          subtitle: 'From Storage',
          icon: Icons.folder_open_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _pickAndOpenFile(context),
        ),

        // 2. Signature Vault
        _buildHubCard(
          title: 'Signature Vault',
          subtitle: 'Draw & Adopt',
          icon: Icons.draw_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _openSignatureVault(context),
        ),

        // 3. Sample NDA
        _buildHubCard(
          title: 'Legal NDA',
          subtitle: '2 Pages • Sign',
          icon: Icons.handshake_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFB45309)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _openSampleNda(context),
        ),

        // 4. Sample Invoice
        _buildHubCard(
          title: 'Tax Invoice',
          subtitle: '1 Page • Stamp',
          icon: Icons.receipt_long_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () => _openSampleInvoice(context),
        ),
      ],
    );
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!item.isSample && item.path != null)
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18, color: Colors.blueAccent),
                    tooltip: 'Share Document',
                    onPressed: () {
                      ShareService.shareExistingFile(
                        filePath: item.path!,
                        fileName: item.name,
                      );
                    },
                  ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
              ],
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('PDF Studio Pro'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versatile Android PDF Suite for reading, digitally signing, stamping, annotating, and sharing documents.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text('• Version: 1.0.0 (Google Play Store Ready)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('• Package: com.oktamatija.pdfstudiopro', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• License: GNU General Public License v3 (GPLv3)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• WhatsApp & WhatsApp Business Direct Integration', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• Web Showcase: https://oktama.freedev.app/', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
            Text('• GitHub: github.com/oktamatija/pdfstudiopro', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
          ],
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
