class WeightLog {
  final String id;
  final String cattleId;
  final DateTime date;
  final double weight;

  WeightLog({
    required this.id,
    required this.cattleId,
    required this.date,
    required this.weight,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
        id: json['id'] ?? '',
        cattleId: json['cattle_id'] ?? '',
        date: DateTime.parse(json['date']),
        weight: (json['weight'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'cattle_id': cattleId,
        'date': date.toIso8601String().split('T')[0],
        'weight': weight,
      };
}
