class PdfDocItem {
  final String id;
  final String name;
  final String? path;
  final int pageCount;
  final int sizeInBytes;
  final DateTime modifiedDate;
  final bool isSample;

  PdfDocItem({
    required this.id,
    required this.name,
    this.path,
    required this.pageCount,
    required this.sizeInBytes,
    required this.modifiedDate,
    this.isSample = false,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'pageCount': pageCount,
        'sizeInBytes': sizeInBytes,
        'modifiedDate': modifiedDate.toIso8601String(),
        'isSample': isSample,
      };

  factory PdfDocItem.fromJson(Map<String, dynamic> json) => PdfDocItem(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String?,
        pageCount: json['pageCount'] as int? ?? 1,
        sizeInBytes: json['sizeInBytes'] as int? ?? 0,
        modifiedDate: DateTime.tryParse(json['modifiedDate'] as String? ?? '') ?? DateTime.now(),
        isSample: json['isSample'] as bool? ?? false,
      );
}
