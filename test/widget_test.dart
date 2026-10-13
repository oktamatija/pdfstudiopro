import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_tools/main.dart';

void main() {
  testWidgets('PdfStudioApp renders home screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfStudioApp());
    await tester.pump();

    // Verify main app title exists
    expect(find.text('PDF Studio Pro'), findsWidgets);
  });
}
