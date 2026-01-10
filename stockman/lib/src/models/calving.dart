class Calving {
  final String id;
  final String? pregnancyId;
  final String cowId;
  final String? calfId;
  final DateTime calvingDate;
  final String outcome; // 'live', 'stillborn'
  final String? notes;

  Calving({
    required this.id,
    this.pregnancyId,
    required this.cowId,
    this.calfId,
    required this.calvingDate,
    this.outcome = 'live',
    this.notes,
  });

  factory Calving.fromJson(Map<String, dynamic> json) => Calving(
        id: json['id'] ?? '',
        pregnancyId: json['pregnancy_id'],
        cowId: json['cow_id'] ?? '',
        calfId: json['calf_id'],
        calvingDate: DateTime.parse(json['calving_date']),
        outcome: json['outcome'] ?? 'live',
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        if (pregnancyId != null) 'pregnancy_id': pregnancyId,
        'cow_id': cowId,
        if (calfId != null) 'calf_id': calfId,
        'calving_date': calvingDate.toIso8601String().split('T')[0],
        'outcome': outcome,
        if (notes != null) 'notes': notes,
      };
}
