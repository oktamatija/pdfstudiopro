import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_doc_item.dart';
import '../models/saved_signature.dart';

class StorageService {
  static const String _keyRecentFiles = 'recent_pdf_files';
  static const String _keySignatures = 'saved_user_signatures';

  /// Save PDF permanently to local device storage (Downloads or Application Documents)
  static Future<String> savePdfToDevice(Uint8List pdfBytes, String fileName) async {
    final cleanName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';

    Directory? dir;
    if (Platform.isAndroid) {
      // Try to save to Downloads directory if accessible, otherwise app docs
      final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (extDirs != null && extDirs.isNotEmpty) {
        dir = extDirs.first;
      }
    }
    dir ??= await getApplicationDocumentsDirectory();

    final file = File('${dir.path}/$cleanName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file.path;
  }

  /// Pick an existing PDF file from device storage
  static Future<PlatformFile?> pickPdfFile() async {
    return await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  /// Load recent files list
  static Future<List<PdfDocItem>> loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyRecentFiles) ?? [];
    return jsonList.map((item) {
      try {
        return PdfDocItem.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<PdfDocItem>().toList();
  }

  /// Add or update a file in the recent files list
  static Future<void> addRecentFile(PdfDocItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await loadRecentFiles();
    items.removeWhere((i) => i.id == item.id || (i.path != null && i.path == item.path));
    items.insert(0, item);

    // Keep top 15 recent items
    final trimmed = items.take(15).toList();
    final jsonList = trimmed.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_keyRecentFiles, jsonList);
  }

  /// Load saved signatures
  static Future<List<SavedSignature>> loadSavedSignatures() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keySignatures) ?? [];
    return jsonList.map((item) {
      try {
        return SavedSignature.fromJson(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<SavedSignature>().toList();
  }

  /// Save a new signature to user presets
  static Future<void> saveSignature(SavedSignature signature) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadSavedSignatures();
    list.removeWhere((s) => s.id == signature.id);
    list.insert(0, signature);

    final jsonList = list.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_keySignatures, jsonList);
  }

  /// Delete a saved signature
  static Future<void> deleteSignature(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadSavedSignatures();
    list.removeWhere((s) => s.id == id);

    final jsonList = list.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_keySignatures, jsonList);
  }
}
