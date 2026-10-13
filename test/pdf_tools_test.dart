import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools/models/annotation_model.dart';
import 'package:pdf_tools/services/pdf_engine.dart';
import 'package:pdf_tools/providers/pdf_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF Engine creates valid Sample NDA and Invoice', () async {
    final ndaBytes = await PdfEngine.createSampleNda();
    expect(ndaBytes.isNotEmpty, true);
    expect(ndaBytes.length > 1000, true);

    final invoiceBytes = await PdfEngine.createSampleInvoice();
    expect(invoiceBytes.isNotEmpty, true);
    expect(invoiceBytes.length > 1000, true);
  });

  test('PDF Engine correctly counts pages', () async {
    final ndaBytes = await PdfEngine.createSampleNda();
    final count = await PdfEngine.getPageCount(ndaBytes);
    expect(count, 2);

    final invoiceBytes = await PdfEngine.createSampleInvoice();
    final invoiceCount = await PdfEngine.getPageCount(invoiceBytes);
    expect(invoiceCount, 1);
  });

  test('PdfProvider state management flow', () async {
    final provider = PdfProvider();
    final invoiceBytes = await PdfEngine.createSampleInvoice();

    await provider.loadPdf(
      bytes: invoiceBytes,
      name: 'Test_Invoice.pdf',
      isSample: true,
    );

    expect(provider.fileName, 'Test_Invoice.pdf');
    expect(provider.totalPages, 1);
    expect(provider.currentPageIndex, 0);

    // Place text note
    provider.placeTextBox('Test Approval Note');
    expect(provider.currentAnnotations.length, 1);
    expect(provider.currentAnnotations.first.text, 'Test Approval Note');

    // Place Stamp
    provider.placeStamp(StampType.approved);
    expect(provider.currentAnnotations.length, 2);

    // Test Undo
    expect(provider.canUndo, true);
    provider.undo();
    expect(provider.currentAnnotations.length, 1);

    // Test Redo
    expect(provider.canRedo, true);
    provider.redo();
    expect(provider.currentAnnotations.length, 2);

    // Switch tool modes
    provider.setEditorMode(EditorMode.sign);
    expect(provider.editorMode, EditorMode.sign);

    provider.setReadingMode(ReadingMode.night);
    expect(provider.readingMode, ReadingMode.night);
  });
}
