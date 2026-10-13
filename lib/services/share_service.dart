import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Save bytes to a temporary or persistent file for sharing
  static Future<File> prepareFileForSharing(Uint8List pdfBytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final cleanName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
    final file = File('${tempDir.path}/$cleanName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  /// Direct share of an existing file on disk (WhatsApp, Mail, etc.)
  static Future<ShareResult> shareExistingFile({
    required String filePath,
    required String fileName,
  }) async {
    final xFile = XFile(filePath, mimeType: 'application/pdf', name: fileName);
    return await Share.shareXFiles(
      [xFile],
      subject: 'Document: $fileName',
      text: 'Sharing document "$fileName" via PDF Studio Pro.',
    );
  }

  /// Universal Android Sharesheet (Supports WhatsApp, WA Business, Gmail, Quick Share, Bluetooth, etc.)
  static Future<ShareResult> shareDocument({
    required Uint8List pdfBytes,
    required String fileName,
    String? subject,
    String? text,
  }) async {
    final file = await prepareFileForSharing(pdfBytes, fileName);
    final xFile = XFile(file.path, mimeType: 'application/pdf', name: fileName);
    return await Share.shareXFiles(
      [xFile],
      subject: subject ?? 'Document: $fileName',
      text: text ?? 'Sharing document "$fileName" via PDF Studio Pro.',
    );
  }

  /// Targeted Share to WhatsApp / WhatsApp Business
  static Future<void> shareToWhatsApp({
    required Uint8List pdfBytes,
    required String fileName,
    bool isBusiness = false,
  }) async {
    final file = await prepareFileForSharing(pdfBytes, fileName);
    final xFile = XFile(file.path, mimeType: 'application/pdf', name: fileName);

    final appTitle = isBusiness ? 'WhatsApp Business' : 'WhatsApp';
    await Share.shareXFiles(
      [xFile],
      subject: 'Document via $appTitle',
      text: 'Sharing signed PDF via $appTitle.',
    );
  }

  /// Targeted Share via Email (Gmail, Outlook, Yahoo)
  static Future<void> shareViaEmail({
    required Uint8List pdfBytes,
    required String fileName,
    String recipient = '',
    String subject = '',
    String body = '',
  }) async {
    final file = await prepareFileForSharing(pdfBytes, fileName);
    final xFile = XFile(file.path, mimeType: 'application/pdf', name: fileName);

    final defaultSubject = subject.isNotEmpty ? subject : 'Signed PDF Document: $fileName';
    final defaultBody = body.isNotEmpty ? body : 'Please find attached the signed PDF document: $fileName.\n\nGenerated with PDF Studio Pro.';

    await Share.shareXFiles(
      [xFile],
      subject: defaultSubject,
      text: defaultBody,
    );
  }

  /// Share to other devices (Quick Share / Nearby Share / Bluetooth)
  static Future<void> shareToOtherDevices({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final file = await prepareFileForSharing(pdfBytes, fileName);
    final xFile = XFile(file.path, mimeType: 'application/pdf', name: fileName);

    await Share.shareXFiles(
      [xFile],
      subject: 'Send to Device: $fileName',
      text: 'Select Quick Share / Nearby Share or Bluetooth to beam this PDF to nearby Android phones, tablets, or Windows PCs.',
    );
  }

  /// Direct Print to connected WiFi / Bluetooth / USB printers
  static Future<void> printDocument({
    required Uint8List pdfBytes,
    required String documentName,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: documentName,
    );
  }
}
