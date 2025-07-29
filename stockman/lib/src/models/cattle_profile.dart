import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/models/vaccination_model.dart';

class Cattle {
  final String id;
  final DateTime dateOfBirth;
  final int group;
  final String sex;
  final Map<String, double> breed;
  final Map<String, dynamic> weight;
  final Map<DateTime, String> farms;
  final Map<DateTime, String> camps;
  // final String status; // 'Active', 'Sold', etc.
  // final String acquisitionType; // 'Born', 'Bought'
  // final DateTime acquisitionDate; // If born, then == dateOfBirth

  // Optional
  // final String? motherId; // can be null if Unknown
  // final String? fatherId; // can be null if Unknown

  // // Optional / management fields
  // final bool? isPregnant;
  // final DateTime? lastCalvingDate;
  // final int? numberOfCalves;
  // final String? healthStatus;
  // final List<VaccinationModel>? vaccinationRecords;
  // final String? notes;

  Cattle(
      // this.motherId,
      // this.fatherId,
      // this.isPregnant,
      // this.lastCalvingDate,
      // this.numberOfCalves,
      // this.healthStatus,
      // this.vaccinationRecords,
      // this.notes,
      {
    required this.id,
    required this.dateOfBirth,
    required this.group,
    required this.sex,
    required this.breed,
    required this.weight,
    required this.farms,
    required this.camps,
    // required this.status, // 'Active', 'Sold', etc.
    // required this.acquisitionType, // 'Born', 'Bought'
    // required this.acquisitionDate, // If born, then == dateOfBirth
  });

  // Factory constructor from Firestore DocumentSnapshot
  factory Cattle.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Cattle(
      id: doc.id,
      dateOfBirth: (data['dateOfBirth'] is Timestamp)
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : DateTime(1950, 1, 1),
      group: data['group'] ?? 0,
      sex: data['sex'] ?? 'Unknown',
      breed: Map<String, double>.from(data['breed'] ?? {'Unknown': 1.0}),
      weight: Map<String, dynamic>.from(data['weight'] ?? {'1950-01-01': 0.0}),
      farms:
          Map<DateTime, String>.from(data['farm'] ?? {RANDOMDATE: 'Unknown'}),
      camps:
          Map<DateTime, String>.from(data['camp'] ?? {RANDOMDATE: 'Unknown'}),
      // status: data['status'] ?? 'Active',
      // acquisitionType: data['acquisitionType'] ?? 'Born',
      // acquisitionDate: data['acquisitionDate'] ?? RANDOMDATE,
    );
  }

  // Optional: for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'group': group,
      'sex': sex,
      'breed': breed,
      'weight': weight,
      'farms': farms,
      'camps': camps,
    };
  }
}
