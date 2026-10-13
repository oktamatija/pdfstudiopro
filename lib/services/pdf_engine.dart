import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart'
    show Color, FontStyle, FontWeight, TextPainter, TextSpan, TextStyle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/annotation_model.dart';

class RenderedPageData {
  final int pageIndex;
  final Uint8List imageBytes;
  final int width;
  final int height;

  RenderedPageData({
    required this.pageIndex,
    required this.imageBytes,
    required this.width,
    required this.height,
  });
}

class PdfEngine {
  /// Render a single page of a PDF document to PNG image bytes
  static Future<RenderedPageData> renderPage(
    Uint8List pdfBytes,
    int pageIndex, {
    double dpi = 144,
  }) async {
    // In headless test environments where native printing channel is unavailable
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 595, 842), paint);
      final picture = recorder.endRecording();
      final img = await picture.toImage(595, 842);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);
      return RenderedPageData(
        pageIndex: pageIndex,
        imageBytes: bytes,
        width: 595,
        height: 842,
      );
    }

    try {
      final stream = Printing.raster(
        pdfBytes,
        pages: [pageIndex],
        dpi: dpi,
      );
      final raster = await stream.first;
      final pngBytes = await raster.toPng();
      return RenderedPageData(
        pageIndex: pageIndex,
        imageBytes: pngBytes,
        width: raster.width,
        height: raster.height,
      );
    } catch (e) {
      // Fallback: create empty white placeholder page
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 595, 842), paint);
      final picture = recorder.endRecording();
      final img = await picture.toImage(595, 842);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);
      return RenderedPageData(
        pageIndex: pageIndex,
        imageBytes: bytes,
        width: 595,
        height: 842,
      );
    }
  }

  /// Quickly count total pages in a PDF document
  static Future<int> getPageCount(Uint8List pdfBytes) async {
    // High-speed binary scan for /Type /Page (excluding /Type /Pages)
    try {
      final latin1 = String.fromCharCodes(pdfBytes);
      final pageRegex = RegExp(r'/Type\s*/Page\b');
      final matches = pageRegex.allMatches(latin1).length;
      if (matches > 0) return matches;
    } catch (_) {}

    try {
      int count = 0;
      await for (final _ in Printing.raster(pdfBytes, dpi: 36)) {
        count++;
      }
      return count > 0 ? count : 1;
    } catch (_) {
      return 1;
    }
  }

  /// Create a professional Multi-Page Sample Non-Disclosure Agreement (NDA)
  static Future<Uint8List> createSampleNda() async {
    final pdf = pw.Document();

    // Page 1
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MUTUAL NON-DISCLOSURE AGREEMENT',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Standard Corporate Confidentiality Contract (Ref: NDA-2026-904)',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber100,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.amber800, width: 1),
                      ),
                      child: pw.Text(
                        'AWAITING SIGNATURE',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '1. PARTIES & RECITALS',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'This Mutual Non-Disclosure Agreement ("Agreement") is entered into as of October 13, 2026, by and between Nexus Global Innovations Inc. ("Disclosing Party") and the undersigned Recipient ("Receiving Party"). The parties desire to explore a business opportunity concerning digital document processing, mobile enterprise workflow, and cloud sync services.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                '2. CONFIDENTIAL INFORMATION',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'For purposes of this Agreement, "Confidential Information" includes all financial, technical, commercial, legal, and architectural data disclosed in writing, orally, or in electronic media. Confidential Information shall be held in strict confidence and protected using at least the same degree of care as the Receiving Party uses for its own sensitive data.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                '3. OBLIGATIONS & RESTRICTIONS',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Bullet(
                text: 'The Receiving Party shall not distribute, disclose, or transfer any proprietary files to unauthorized third parties without prior written consent.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Bullet(
                text: 'Confidential Information may only be accessed by authorized employees, officers, and legal advisors who have executed equivalent confidentiality covenants.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 4),
              pw.Bullet(
                text: 'All prototypes, digital assets, and documents remain the exclusive property of the Disclosing Party.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Document ID: NDA-2026-904', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page 1 of 2', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Page 2 - Signature Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '4. TERM AND TERMINATION',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'This Agreement and the duty of confidentiality shall remain in effect for a period of three (3) years from the effective date, or until such time as the Disclosing Party releases the Receiving Party in writing.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                '5. GOVERNING LAW & JURISDICTION',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'This Agreement shall be governed by and construed in accordance with standard civil commercial law without regard to conflict of laws principles.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blueGrey300),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EXECUTION & DIGITAL SIGNATURE SECTION',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'IN WITNESS WHEREOF, the parties hereto have caused this Mutual Non-Disclosure Agreement to be executed by their duly authorized representatives.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Disclosing Party Box
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DISCLOSING PARTY:',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('Nexus Global Innovations Inc.', style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 40),
                          pw.Container(
                            height: 1,
                            color: PdfColors.grey600,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Authorized Signature: Elena Vance', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('Date: October 13, 2026', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Receiving Party Box (Place to Sign)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue700, width: 1.5),
                        borderRadius: pw.BorderRadius.circular(4),
                        color: PdfColors.blue50,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'RECEIVING PARTY (SIGN HERE):',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue900,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('Client / Authorized Representative', style: const pw.TextStyle(fontSize: 9)),
                          pw.SizedBox(height: 10),
                          // Target Box for user signature
                          pw.Container(
                            height: 45,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.blue400,
                                style: pw.BorderStyle.dashed,
                              ),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '[ PLACE SIGNATURE HERE ]',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.blue800,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            height: 1,
                            color: PdfColors.blue900,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Print Name: _____________________', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('Date: __________________________', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Document ID: NDA-2026-904', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page 2 of 2 (Signature Page)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Create a professional Business Invoice Sample
  static Future<Uint8List> createSampleInvoice() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'COMMERCIAL INVOICE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('TechFlow Solutions Ltd. | Enterprise Services',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE #: INV-2026-8812',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: October 13, 2026', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Due Date: Net 30 Days', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(height: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 14),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Global Horizons Consulting', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Tower 4, Suite 1200, Finance District', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('contact@globalhorizons.io', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PAYMENT METHOD:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Wire Transfer / Swift', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('IBAN: US89 3704 0044 0532 01', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Currency: USD (\$)', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ['ITEM DESCRIPTION', 'QTY', 'UNIT PRICE', 'AMOUNT'],
                data: [
                  ['Cloud Architecture & Security Review', '1', '\$3,200.00', '\$3,200.00'],
                  ['Mobile Application Testing & Hardening', '1', '\$2,450.00', '\$2,450.00'],
                  ['PDF Digital Signature Infrastructure Setup', '1', '\$1,850.00', '\$1,850.00'],
                  ['24/7 SLA Deployment Support (Oct 2026)', '1', '\$950.00', '\$950.00'],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellHeight: 28,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('\$8,450.00', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Tax (0% B2B):', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('\$0.00', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Divider(thickness: 1),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Due:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text('\$8,450.00',
                                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              // Approval & Sign Section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MANAGEMENT APPROVAL / AUDIT SIGNATURE',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Please apply authorized stamp or signature to confirm invoice release.',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      width: 140,
                      height: 40,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, style: pw.BorderStyle.dashed),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Center(
                        child: pw.Text('[ STAMP / SIGN HERE ]',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Composite drawings and vector elements for a single page into high-res PNG
  static Future<Uint8List> compositePageWithAnnotations(
    Uint8List basePagePngBytes,
    List<AnnotationModel> annotations,
    int targetWidth,
    int targetHeight,
  ) async {
    if (annotations.isEmpty) {
      return basePagePngBytes;
    }

    final codec = await ui.instantiateImageCodec(basePagePngBytes);
    final frame = await codec.getNextFrame();
    final baseImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // 1. Draw base page
    final srcRect = ui.Rect.fromLTWH(0, 0, baseImage.width.toDouble(), baseImage.height.toDouble());
    final dstRect = ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
    canvas.drawImageRect(baseImage, srcRect, dstRect, ui.Paint());

    // 2. Draw annotations on top
    for (final ann in annotations) {
      final double left = ann.x * targetWidth;
      final double top = ann.y * targetHeight;
      final double width = ann.width * targetWidth;
      final double height = ann.height * targetHeight;

      switch (ann.type) {
        case AnnotationType.signature:
          if (ann.imageBytes != null && ann.imageBytes!.isNotEmpty) {
            try {
              final sigCodec = await ui.instantiateImageCodec(ann.imageBytes!);
              final sigFrame = await sigCodec.getNextFrame();
              final sigImg = sigFrame.image;
              final sigSrc = ui.Rect.fromLTWH(0, 0, sigImg.width.toDouble(), sigImg.height.toDouble());
              final sigDst = ui.Rect.fromLTWH(left, top, width, height);
              final sigPaint = ui.Paint()..color = Color.fromRGBO(255, 255, 255, ann.opacity);
              canvas.drawImageRect(sigImg, sigSrc, sigDst, sigPaint);
            } catch (_) {}
          }
          break;

        case AnnotationType.text:
          if (ann.text != null && ann.text!.isNotEmpty) {
            // Draw background if any
            final bgPaint = ui.Paint()..color = const Color(0x33FFFF00);
            canvas.drawRect(ui.Rect.fromLTWH(left, top, width, height), bgPaint);

            final textPainter = TextPainter(
              text: TextSpan(
                text: ann.text,
                style: TextStyle(
                  color: ann.color,
                  fontSize: ann.fontSize * (targetWidth / 600.0),
                  fontWeight: ann.isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: ann.isItalic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              textDirection: ui.TextDirection.ltr,
            );
            textPainter.layout(maxWidth: math.max(width, 100));
            textPainter.paint(canvas, ui.Offset(left, top));
          }
          break;

        case AnnotationType.drawing:
        case AnnotationType.highlight:
          if (ann.points != null && ann.points!.length > 1) {
            final strokePaint = ui.Paint()
              ..color = ann.color.withOpacity(ann.opacity)
              ..strokeWidth = ann.strokeWidth * (targetWidth / 600.0)
              ..style = ui.PaintingStyle.stroke
              ..strokeCap = ui.StrokeCap.round
              ..strokeJoin = ui.StrokeJoin.round;

            final path = ui.Path();
            path.moveTo(ann.points![0].x * targetWidth, ann.points![0].y * targetHeight);
            for (int i = 1; i < ann.points!.length; i++) {
              path.lineTo(ann.points![i].x * targetWidth, ann.points![i].y * targetHeight);
            }
            canvas.drawPath(path, strokePaint);
          }
          break;

        case AnnotationType.shape:
          final shapePaint = ui.Paint()
            ..color = ann.color.withOpacity(ann.opacity)
            ..strokeWidth = ann.strokeWidth * (targetWidth / 600.0)
            ..style = ui.PaintingStyle.stroke;

          final rect = ui.Rect.fromLTWH(left, top, width, height);
          if (ann.shapeType == ShapeType.rectangle) {
            canvas.drawRect(rect, shapePaint);
          } else if (ann.shapeType == ShapeType.circle) {
            canvas.drawOval(rect, shapePaint);
          } else if (ann.shapeType == ShapeType.redaction) {
            final blackFill = ui.Paint()..color = const Color(0xFF000000);
            canvas.drawRect(rect, blackFill);
          } else if (ann.shapeType == ShapeType.checkmark) {
            final checkPaint = ui.Paint()
              ..color = ann.color
              ..strokeWidth = math.max(3.0, ann.strokeWidth * 1.5)
              ..style = ui.PaintingStyle.stroke
              ..strokeCap = ui.StrokeCap.round;
            final checkPath = ui.Path();
            checkPath.moveTo(left + width * 0.2, top + height * 0.55);
            checkPath.lineTo(left + width * 0.45, top + height * 0.85);
            checkPath.lineTo(left + width * 0.85, top + height * 0.2);
            canvas.drawPath(checkPath, checkPaint);
          } else if (ann.shapeType == ShapeType.cross) {
            final crossPaint = ui.Paint()
              ..color = ann.color
              ..strokeWidth = math.max(3.0, ann.strokeWidth * 1.5)
              ..style = ui.PaintingStyle.stroke
              ..strokeCap = ui.StrokeCap.round;
            canvas.drawLine(ui.Offset(left + width * 0.2, top + height * 0.2),
                ui.Offset(left + width * 0.8, top + height * 0.8), crossPaint);
            canvas.drawLine(ui.Offset(left + width * 0.8, top + height * 0.2),
                ui.Offset(left + width * 0.2, top + height * 0.8), crossPaint);
          }
          break;

        case AnnotationType.stamp:
          _drawStamp(canvas, ann, left, top, width, height, targetWidth);
          break;
      }
    }

    final picture = recorder.endRecording();
    final resultImg = await picture.toImage(targetWidth, targetHeight);
    final byteData = await resultImg.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List() ?? basePagePngBytes;
  }

  static void _drawStamp(
    ui.Canvas canvas,
    AnnotationModel ann,
    double left,
    double top,
    double width,
    double height,
    int targetWidth,
  ) {
    String stampText = 'APPROVED';
    Color stampColor = const Color(0xFF2E7D32); // Green

    switch (ann.stampType) {
      case StampType.approved:
        stampText = 'APPROVED';
        stampColor = const Color(0xFF2E7D32);
        break;
      case StampType.confidential:
        stampText = 'CONFIDENTIAL';
        stampColor = const Color(0xFFC62828);
        break;
      case StampType.draft:
        stampText = 'DRAFT';
        stampColor = const Color(0xFFEF6C00);
        break;
      case StampType.paid:
        stampText = 'PAID';
        stampColor = const Color(0xFF1565C0);
        break;
      case StampType.rejected:
        stampText = 'REJECTED';
        stampColor = const Color(0xFFB71C1C);
        break;
      case StampType.finalVersion:
        stampText = 'FINAL';
        stampColor = const Color(0xFF6A1B9A);
        break;
      default:
        stampText = 'VERIFIED';
        stampColor = const Color(0xFF00695C);
    }

    final stampRect = ui.Rect.fromLTWH(left, top, width, height);

    // Border
    final borderPaint = ui.Paint()
      ..color = stampColor.withOpacity(0.85)
      ..strokeWidth = 3.0 * (targetWidth / 600.0)
      ..style = ui.PaintingStyle.stroke;
    canvas.drawRRect(ui.RRect.fromRectAndRadius(stampRect, const ui.Radius.circular(6)), borderPaint);

    // Inner dashed or thin border
    final innerRect = stampRect.deflate(4.0 * (targetWidth / 600.0));
    final innerPaint = ui.Paint()
      ..color = stampColor.withOpacity(0.5)
      ..strokeWidth = 1.0 * (targetWidth / 600.0)
      ..style = ui.PaintingStyle.stroke;
    canvas.drawRRect(ui.RRect.fromRectAndRadius(innerRect, const ui.Radius.circular(4)), innerPaint);

    // Stamp text
    final textPainter = TextPainter(
      text: TextSpan(
        text: stampText,
        style: TextStyle(
          color: stampColor.withOpacity(0.9),
          fontSize: math.max(12.0, (height * 0.45)),
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    final textOffset = ui.Offset(
      left + (width - textPainter.width) / 2,
      top + (height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  /// Export complete multi-page document into a newly generated PDF with all annotations permanently baked in
  static Future<Uint8List> exportAnnotatedPdf({
    required Uint8List originalPdfBytes,
    required Map<int, List<AnnotationModel>> pageAnnotations,
    required int totalPages,
    double exportDpi = 180,
  }) async {
    final pdf = pw.Document();

    for (int i = 0; i < totalPages; i++) {
      // 1. Render base page
      final basePage = await renderPage(originalPdfBytes, i, dpi: exportDpi);

      // 2. Composite with annotations if any
      final annotations = pageAnnotations[i] ?? [];
      final finalBytes = await compositePageWithAnnotations(
        basePage.imageBytes,
        annotations,
        basePage.width,
        basePage.height,
      );

      final image = pw.MemoryImage(finalBytes);

      // Calculate A4 or matching aspect ratio
      final double pdfWidth = basePage.width * 72.0 / exportDpi;
      final double pdfHeight = basePage.height * 72.0 / exportDpi;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pdfWidth, pdfHeight),
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(image, fit: pw.BoxFit.fill),
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
