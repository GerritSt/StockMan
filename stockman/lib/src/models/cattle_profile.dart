import 'package:cloud_firestore/cloud_firestore.dart';

class CattleProfile {
  CattleProfile({required this.cattleMap});

  final Map<String, dynamic> cattleMap;

  String get docID => cattleMap['Document ID'];
 
  String get tag => (cattleMap['tag'] ?? 'Unknown');

  Map<String, dynamic> get weight {
    return (cattleMap['weight'] ?? {'1950-01-01': 0.0});
  }

  DateTime get birthdate {
    final rawDate = cattleMap['birthdate'];
    if (rawDate is Timestamp) {
      return rawDate.toDate(); // For Firestore Timestamps
    } else if (rawDate is DateTime) {
      return rawDate; // Already a DateTime
    } else {
      // Default or invalid value
      return DateTime(1950, 1, 1);
    }
  }

  int get group => (cattleMap['group'] ?? 0);
  String get sex => (cattleMap['sex'] ?? 'Unknown');
  Map<String, double> get breed => (cattleMap['breed'] ?? {'Unknown': 1.0});
}
