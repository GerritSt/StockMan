class CattleDocument {
  final String id;
  final String cattleId;
  final String type; // 'branding'
  final String filePath;
  final String? title;
  final DateTime uploadedAt;

  CattleDocument({
    required this.id,
    required this.cattleId,
    required this.type,
    required this.filePath,
    this.title,
    required this.uploadedAt,
  });

  factory CattleDocument.fromJson(Map<String, dynamic> json) => CattleDocument(
        id: json['id'] ?? '',
        cattleId: json['cattle_id'] ?? '',
        type: json['type'] ?? 'branding',
        filePath: json['file_path'] ?? '',
        title: json['title'],
        uploadedAt: json['uploaded_at'] != null
            ? DateTime.parse(json['uploaded_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'cattle_id': cattleId,
        'type': type,
        'file_path': filePath,
        if (title != null) 'title': title,
      };
}
