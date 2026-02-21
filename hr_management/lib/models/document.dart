class DocumentModel {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String documentType;
  final String documentName;
  final String fileUrl;
  final int? fileSize;
  final int? uploadedBy;
  final String? uploadedByName;
  final DateTime uploadedAt;

  DocumentModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.documentType,
    required this.documentName,
    required this.fileUrl,
    this.fileSize,
    this.uploadedBy,
    this.uploadedByName,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      documentType: json['document_type'],
      documentName: json['document_name'],
      fileUrl: json['file_url'],
      fileSize: json['file_size'],
      uploadedBy: json['uploaded_by'],
      uploadedByName: json['uploaded_by_name'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get typeIcon {
    switch (documentType) {
      case 'citizenship':
        return '🪪';
      case 'certificate':
        return '📜';
      case 'contract':
        return '📋';
      case 'photo':
        return '🖼️';
      default:
        return '📄';
    }
  }

  bool get isImage =>
      fileUrl.endsWith('.jpg') || fileUrl.endsWith('.jpeg') || fileUrl.endsWith('.png');
}