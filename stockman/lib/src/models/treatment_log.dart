class TreatmentLog {
  final String id;
  final String cattleId;
  final String treatmentName;
  final String? dosage;
  final String? notes;
  final DateTime date;

  TreatmentLog({
    required this.id,
    required this.cattleId,
    required this.treatmentName,
    this.dosage,
    this.notes,
    required this.date,
  });

  factory TreatmentLog.fromJson(Map<String, dynamic> json) => TreatmentLog(
        id: json['id'] ?? '',
        cattleId: json['cattle_id'] ?? '',
        treatmentName: json['treatment_name'] ?? '',
        dosage: json['dosage'],
        notes: json['notes'],
        date: DateTime.parse(json['date']),
      );

  Map<String, dynamic> toJson() => {
        'cattle_id': cattleId,
        'treatment_name': treatmentName,
        if (dosage != null) 'dosage': dosage,
        if (notes != null) 'notes': notes,
        'date': date.toIso8601String().split('T')[0],
      };
}
