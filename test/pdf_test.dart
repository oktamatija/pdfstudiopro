import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('PDF creation test', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text('Test PDF Document'),
          );
        },
      ),
    );
    final Uint8List bytes = await pdf.save();
    expect(bytes.isNotEmpty, true);
    print('Generated PDF bytes length: ${bytes.length}');
  });
}
