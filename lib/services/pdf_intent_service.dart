import 'package:flutter/services.dart';

class IncomingPdfDocument {
  final String name;
  final String path;
  final Uint8List bytes;

  IncomingPdfDocument({
    required this.name,
    required this.path,
    required this.bytes,
  });
}

class PdfIntentService {
  static const MethodChannel _channel = MethodChannel('com.antigravity.pdfreader/intent');

  /// Check if the application was launched with a PDF document from WhatsApp, Email, etc.
  static Future<IncomingPdfDocument?> getInitialPdf() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('getInitialPdf');
      if (result is Map) {
        final name = result['name'] as String? ?? 'Document.pdf';
        final path = result['path'] as String? ?? '';
        final bytes = result['bytes'] as Uint8List?;
        if (bytes != null && bytes.isNotEmpty) {
          return IncomingPdfDocument(name: name, path: path, bytes: bytes);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Listen for incoming PDFs when app is in the background and user taps a PDF in WhatsApp / Email
  static void setPdfOpenedListener(void Function(IncomingPdfDocument doc) onOpened) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPdfOpened') {
        final args = call.arguments;
        if (args is Map) {
          final name = args['name'] as String? ?? 'Document.pdf';
          final path = args['path'] as String? ?? '';
          final bytes = args['bytes'] as Uint8List?;
          if (bytes != null && bytes.isNotEmpty) {
            onOpened(IncomingPdfDocument(name: name, path: path, bytes: bytes));
          }
        }
      }
    });
  }
}
