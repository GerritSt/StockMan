import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/config/constants.dart';

class Cattle {
  final String id;
  final String tag;
  final DateTime birthDate;
  final int group;
  final String sex;
  final Map<String, double> breed;
  final Map<String, dynamic> weight;
  final Map<DateTime, String> farm;
  final Map<DateTime, String> camp;

  Cattle({
    required this.id,
    required this.tag,
    required this.birthDate,
    required this.group,
    required this.sex,
    required this.breed,
    required this.weight,
    required this.farm,
    required this.camp,
  });

  // Factory constructor from Firestore DocumentSnapshot
  factory Cattle.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Cattle(
      id: doc.id,
      tag: data['tag'] ?? 'Unknown',
      birthDate: (data['birthdate'] is Timestamp)
          ? (data['birthdate'] as Timestamp).toDate()
          : DateTime(1950, 1, 1),
      group: data['group'] ?? 0,
      sex: data['sex'] ?? 'Unknown',
      breed: Map<String, double>.from(data['breed'] ?? {'Unknown': 1.0}),
      weight: Map<String, dynamic>.from(data['weight'] ?? {'1950-01-01': 0.0}),
      farm: Map<DateTime, String>.from(data['farm'] ?? {RANDOMDATE: 'Unknown'}),
      camp: Map<DateTime, String>.from(data['camp'] ?? {RANDOMDATE: 'Unknown'}),
    );
  }

  // Optional: for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'tag': tag,
      'birthdate': Timestamp.fromDate(birthDate),
      'group': group,
      'sex': sex,
      'breed': breed,
      'weight': weight,
      'farm': farm,
      'camp': camp,
    };
  }
}
