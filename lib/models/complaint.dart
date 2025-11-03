class Complaint {
  final String? id;
  final String title;
  final String description;
  final String? category;
  final String? summary;
  final List<String>? keyPoints;
  final int? severity;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  Complaint({
    this.id,
    required this.title,
    required this.description,
    this.category,
    this.summary,
    this.keyPoints,
    this.severity = 1,
    this.status = 'nouveau',
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  // Conversion depuis JSON
  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'],
      summary: json['summary'],
      keyPoints: json['key_points'] != null 
          ? List<String>.from(json['key_points'])
          : null,
      severity: json['severity'] ?? 1,
      status: json['status'] ?? 'nouveau',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userId: json['user_id'],
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'summary': summary,
      'key_points': keyPoints,
      'severity': severity,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }
}