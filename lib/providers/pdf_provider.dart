import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/annotation_model.dart';
import '../models/pdf_doc_item.dart';
import '../services/pdf_engine.dart';
import '../services/storage_service.dart';

enum EditorMode {
  read,
  sign,
  draw,
  highlight,
  text,
  shape,
  stamp,
  pages,
}

enum ReadingMode {
  normal,
  night, // Inverted dark contrast
  sepia, // Warm amber paper tone
}

class PdfProvider with ChangeNotifier {
  final Uuid _uuid = const Uuid();

  // Document State
  Uint8List? _pdfBytes;
  String _fileName = 'Untitled.pdf';
  String? _filePath;
  int _totalPages = 0;
  int _currentPageIndex = 0;
  bool _isLoading = false;
  String _statusMessage = '';

  // Rendered page cache: pageIndex -> RenderedPageData
  final Map<int, RenderedPageData> _pageCache = {};

  // Annotations per page: pageIndex -> List<AnnotationModel>
  final Map<int, List<AnnotationModel>> _pageAnnotations = {};

  // Undo / Redo Stacks (snapshots of annotations)
  final List<Map<int, List<AnnotationModel>>> _undoStack = [];
  final List<Map<int, List<AnnotationModel>>> _redoStack = [];

  // Selected annotation on the active page
  AnnotationModel? _selectedAnnotation;

  // Active Tool Settings
  EditorMode _editorMode = EditorMode.read;
  ReadingMode _readingMode = ReadingMode.normal;
  Color _penColor = const Color(0xFF1565C0); // Royal Blue default ink
  double _strokeWidth = 3.0;
  double _fontSize = 16.0;
  ShapeType _shapeType = ShapeType.rectangle;
  StampType _stampType = StampType.approved;
  double _zoomScale = 1.0;
  bool _isFullscreen = false;

  // Freehand drawing in-progress points
  List<DrawingPoint> _currentDrawingPoints = [];

  // Getters
  Uint8List? get pdfBytes => _pdfBytes;
  String get fileName => _fileName;
  String? get filePath => _filePath;
  int get totalPages => _totalPages;
  int get currentPageIndex => _currentPageIndex;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  EditorMode get editorMode => _editorMode;
  ReadingMode get readingMode => _readingMode;
  Color get penColor => _penColor;
  double get strokeWidth => _strokeWidth;
  double get fontSize => _fontSize;
  ShapeType get shapeType => _shapeType;
  StampType get stampType => _stampType;
  double get zoomScale => _zoomScale;
  bool get isFullscreen => _isFullscreen;
  AnnotationModel? get selectedAnnotation => _selectedAnnotation;
  List<DrawingPoint> get currentDrawingPoints => _currentDrawingPoints;

  List<AnnotationModel> get currentAnnotations =>
      _pageAnnotations[_currentPageIndex] ?? [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  RenderedPageData? get currentPageData => _pageCache[_currentPageIndex];

  // ================= LOAD DOCUMENTS ================= //

  Future<void> loadPdf({
    required Uint8List bytes,
    required String name,
    String? path,
    bool isSample = false,
  }) async {
    _isLoading = true;
    _statusMessage = 'Loading document...';
    notifyListeners();

    try {
      _pdfBytes = bytes;
      _fileName = name;
      _filePath = path;
      _currentPageIndex = 0;
      _pageCache.clear();
      _pageAnnotations.clear();
      _undoStack.clear();
      _redoStack.clear();
      _selectedAnnotation = null;

      _statusMessage = 'Analyzing pages...';
      notifyListeners();

      _totalPages = await PdfEngine.getPageCount(bytes);

      // Render first page immediately
      _statusMessage = 'Rendering Page 1...';
      notifyListeners();

      final firstPage = await PdfEngine.renderPage(bytes, 0);
      _pageCache[0] = firstPage;

      // Add to recent files
      await StorageService.addRecentFile(
        PdfDocItem(
          id: _uuid.v4(),
          name: name,
          path: path,
          pageCount: _totalPages,
          sizeInBytes: bytes.length,
          modifiedDate: DateTime.now(),
          isSample: isSample,
        ),
      );

      _isLoading = false;
      _statusMessage = '';
      notifyListeners();

      // Preload next page in background if available
      _preloadAdjacentPages();
    } catch (e) {
      _isLoading = false;
      _statusMessage = 'Failed to load PDF: $e';
      notifyListeners();
    }
  }

  Future<void> loadSampleNda() async {
    final bytes = await PdfEngine.createSampleNda();
    await loadPdf(
      bytes: bytes,
      name: 'Mutual_NDA_Agreement.pdf',
      isSample: true,
    );
  }

  Future<void> loadSampleInvoice() async {
    final bytes = await PdfEngine.createSampleInvoice();
    await loadPdf(
      bytes: bytes,
      name: 'Commercial_Invoice_2026.pdf',
      isSample: true,
    );
  }

  // ================= PAGE NAVIGATION ================= //

  Future<void> setCurrentPage(int index) async {
    if (index < 0 || index >= _totalPages || index == _currentPageIndex) return;

    _currentPageIndex = index;
    _selectedAnnotation = null;
    notifyListeners();

    if (!_pageCache.containsKey(index) && _pdfBytes != null) {
      _isLoading = true;
      _statusMessage = 'Rendering Page ${index + 1}...';
      notifyListeners();

      try {
        final pageData = await PdfEngine.renderPage(_pdfBytes!, index);
        _pageCache[index] = pageData;
      } catch (_) {}

      _isLoading = false;
      _statusMessage = '';
      notifyListeners();
    }

    _preloadAdjacentPages();
  }

  void nextPage() {
    if (_currentPageIndex < _totalPages - 1) {
      setCurrentPage(_currentPageIndex + 1);
    }
  }

  void previousPage() {
    if (_currentPageIndex > 0) {
      setCurrentPage(_currentPageIndex - 1);
    }
  }

  Future<void> _preloadAdjacentPages() async {
    if (_pdfBytes == null) return;
    final next = _currentPageIndex + 1;
    final prev = _currentPageIndex - 1;

    if (next < _totalPages && !_pageCache.containsKey(next)) {
      PdfEngine.renderPage(_pdfBytes!, next).then((data) {
        _pageCache[next] = data;
        notifyListeners();
      }).catchError((_) {});
    }

    if (prev >= 0 && !_pageCache.containsKey(prev)) {
      PdfEngine.renderPage(_pdfBytes!, prev).then((data) {
        _pageCache[prev] = data;
        notifyListeners();
      }).catchError((_) {});
    }
  }

  // ================= EDITOR TOOL SETTINGS ================= //

  void setEditorMode(EditorMode mode) {
    _editorMode = mode;
    _selectedAnnotation = null;
    _currentDrawingPoints.clear();
    notifyListeners();
  }

  void setReadingMode(ReadingMode mode) {
    _readingMode = mode;
    notifyListeners();
  }

  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  void setPenColor(Color color) {
    _penColor = color;
    if (_selectedAnnotation != null) {
      _selectedAnnotation!.colorValue = color.value;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    if (_selectedAnnotation != null && _selectedAnnotation!.type == AnnotationType.text) {
      _selectedAnnotation!.fontSize = size;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void setShapeType(ShapeType type) {
    _shapeType = type;
    notifyListeners();
  }

  void setStampType(StampType type) {
    _stampType = type;
    notifyListeners();
  }

  void setZoomScale(double scale) {
    _zoomScale = scale.clamp(0.5, 4.0);
    notifyListeners();
  }

  // ================= ANNOTATION MANIPULATION ================= //

  void selectAnnotation(AnnotationModel? annotation) {
    _selectedAnnotation = annotation;
    notifyListeners();
  }

  void addAnnotation(AnnotationModel annotation) {
    _saveUndoSnapshot();
    if (!_pageAnnotations.containsKey(annotation.pageIndex)) {
      _pageAnnotations[annotation.pageIndex] = [];
    }
    _pageAnnotations[annotation.pageIndex]!.add(annotation);
    _selectedAnnotation = annotation;
    notifyListeners();
  }

  void updateAnnotation(AnnotationModel updated) {
    final list = _pageAnnotations[updated.pageIndex];
    if (list != null) {
      final idx = list.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        list[idx] = updated;
        _selectedAnnotation = updated;
        notifyListeners();
      }
    }
  }

  void removeAnnotation(String id) {
    _saveUndoSnapshot();
    for (final key in _pageAnnotations.keys) {
      _pageAnnotations[key]!.removeWhere((a) => a.id == id);
    }
    if (_selectedAnnotation?.id == id) {
      _selectedAnnotation = null;
    }
    notifyListeners();
  }

  // Drawing Path Stream
  void startDrawing(DrawingPoint point) {
    _currentDrawingPoints = [point];
    notifyListeners();
  }

  void updateDrawing(DrawingPoint point) {
    _currentDrawingPoints.add(point);
    notifyListeners();
  }

  void finishDrawing() {
    if (_currentDrawingPoints.length > 1) {
      final isHighlighter = _editorMode == EditorMode.highlight;
      final annotation = AnnotationModel(
        id: _uuid.v4(),
        type: isHighlighter ? AnnotationType.highlight : AnnotationType.drawing,
        pageIndex: _currentPageIndex,
        x: 0.0,
        y: 0.0,
        width: 1.0,
        height: 1.0,
        points: List.from(_currentDrawingPoints),
        colorValue: isHighlighter ? _penColor.withOpacity(0.4).value : _penColor.value,
        strokeWidth: isHighlighter ? (_strokeWidth * 3.5) : _strokeWidth,
        opacity: isHighlighter ? 0.35 : 1.0,
      );
      addAnnotation(annotation);
    }
    _currentDrawingPoints = [];
    notifyListeners();
  }

  // Quick Stamp Placer
  void placeStamp(StampType type, {double x = 0.35, double y = 0.4}) {
    final annotation = AnnotationModel(
      id: _uuid.v4(),
      type: AnnotationType.stamp,
      pageIndex: _currentPageIndex,
      x: x,
      y: y,
      width: 0.35,
      height: 0.08,
      stampType: type,
    );
    addAnnotation(annotation);
  }

  // Quick Shape Placer
  void placeShape(ShapeType type, {double x = 0.3, double y = 0.3}) {
    final annotation = AnnotationModel(
      id: _uuid.v4(),
      type: AnnotationType.shape,
      pageIndex: _currentPageIndex,
      x: x,
      y: y,
      width: (type == ShapeType.checkmark || type == ShapeType.cross) ? 0.12 : 0.4,
      height: (type == ShapeType.checkmark || type == ShapeType.cross) ? 0.12 : 0.15,
      shapeType: type,
      colorValue: (type == ShapeType.checkmark)
          ? const Color(0xFF2E7D32).value
          : (type == ShapeType.cross)
              ? const Color(0xFFC62828).value
              : _penColor.value,
      strokeWidth: _strokeWidth,
    );
    addAnnotation(annotation);
  }

  // Quick Text Box Placer
  void placeTextBox(String text, {double x = 0.2, double y = 0.3}) {
    final annotation = AnnotationModel(
      id: _uuid.v4(),
      type: AnnotationType.text,
      pageIndex: _currentPageIndex,
      x: x,
      y: y,
      width: 0.45,
      height: 0.06,
      text: text,
      colorValue: _penColor.value,
      fontSize: _fontSize,
    );
    addAnnotation(annotation);
  }

  // Quick Signature Placer
  void placeSignature(Uint8List imageBytes, {double x = 0.3, double y = 0.7, double width = 0.38, double height = 0.12}) {
    final annotation = AnnotationModel(
      id: _uuid.v4(),
      type: AnnotationType.signature,
      pageIndex: _currentPageIndex,
      x: x,
      y: y,
      width: width,
      height: height,
      imageBytes: imageBytes,
    );
    addAnnotation(annotation);
  }

  // ================= UNDO / REDO ================= //

  Map<int, List<AnnotationModel>> _cloneAnnotations() {
    return _pageAnnotations.map(
      (k, v) => MapEntry(k, v.map((a) => a.copyWith()).toList()),
    );
  }

  void _saveUndoSnapshot() {
    _undoStack.add(_cloneAnnotations());
    _redoStack.clear();
    if (_undoStack.length > 25) {
      _undoStack.removeAt(0);
    }
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_cloneAnnotations());
    final previous = _undoStack.removeLast();
    _pageAnnotations.clear();
    _pageAnnotations.addAll(
      previous.map((k, v) => MapEntry(k, v.map((a) => a.copyWith()).toList())),
    );
    _selectedAnnotation = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_cloneAnnotations());
    final next = _redoStack.removeLast();
    _pageAnnotations.clear();
    _pageAnnotations.addAll(
      next.map((k, v) => MapEntry(k, v.map((a) => a.copyWith()).toList())),
    );
    _selectedAnnotation = null;
    notifyListeners();
  }

  // ================= EXPORT & COMPOSITE ================= //

  /// Generates the final PDF containing all signatures and edits
  Future<Uint8List> exportFinalPdf({double dpi = 180}) async {
    if (_pdfBytes == null) throw Exception('No PDF loaded');

    _isLoading = true;
    _statusMessage = 'Exporting and flattening PDF document...';
    notifyListeners();

    try {
      final exportedBytes = await PdfEngine.exportAnnotatedPdf(
        originalPdfBytes: _pdfBytes!,
        pageAnnotations: _pageAnnotations,
        totalPages: _totalPages,
        exportDpi: dpi,
      );

      _isLoading = false;
      _statusMessage = '';
      notifyListeners();
      return exportedBytes;
    } catch (e) {
      _isLoading = false;
      _statusMessage = '';
      notifyListeners();
      rethrow;
    }
  }
}
