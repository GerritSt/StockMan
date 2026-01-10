class Pregnancy {
  final String id;
  final String cattleId;
  final DateTime conceptionDate;
  final String conceptionMethod; // 'natural', 'ai', 'ivf'
  final DateTime? expectedCalvingDate;
  final String pregnancyStatus; // 'lactating', 'calved', 'lost'
  final DateTime? endDate;
  final String? notes;

  Pregnancy({
    required this.id,
    required this.cattleId,
    required this.conceptionDate,
    this.conceptionMethod = 'natural',
    this.expectedCalvingDate,
    this.pregnancyStatus = 'lactating',
    this.endDate,
    this.notes,
  });

  factory Pregnancy.fromJson(Map<String, dynamic> json) => Pregnancy(
        id: json['id'] ?? '',
        cattleId: json['cattle_id'] ?? '',
        conceptionDate: DateTime.parse(json['conception_date']),
        conceptionMethod: json['conception_method'] ?? 'natural',
        expectedCalvingDate: json['expected_calving_date'] != null
            ? DateTime.parse(json['expected_calving_date'])
            : null,
        pregnancyStatus: json['pregnancy_status'] ?? 'lactating',
        endDate:
            json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'cattle_id': cattleId,
        'conception_date': conceptionDate.toIso8601String().split('T')[0],
        'conception_method': conceptionMethod,
        if (expectedCalvingDate != null)
          'expected_calving_date':
              expectedCalvingDate!.toIso8601String().split('T')[0],
        'pregnancy_status': pregnancyStatus,
        if (endDate != null)
          'end_date': endDate!.toIso8601String().split('T')[0],
        if (notes != null) 'notes': notes,
      };
}
