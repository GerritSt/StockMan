import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/models/cattle_profile.dart';

class Farmer {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final GeoPoint location;
  final List<Farm> farms;

  Farmer({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.location,
    required this.farms,
  });

  // Factory constructor from Firestore DocumentSnapshot (farms can be passed in)
  factory Farmer.fromSnapshot(
      {required DocumentSnapshot doc, List<Farm> farms = const []}) {
    if (!doc.exists) {
      return Farmer(
        id: doc.id,
        name: 'John',
        surname: 'Doe',
        email: 'john@doe.com',
        phone: '0000000000',
        location: NOWHERE,
        farms: [],
      );
    }

    final data = doc.data() as Map<String, dynamic>;
    return Farmer(
      id: doc.id,
      name: data['name'] ?? 'John',
      surname: data['surname'] ?? 'Doe',
      email: data['email'] ?? 'john@doe.com',
      phone: data['phone'] ?? '0000000000',
      location: data['location'] ?? NOWHERE,
      farms: farms,
    );
  }
}

class Farm {
  final String id;
  final String name;
  final GeoPoint location;
  final String type;
  final int size;
  final List<Camp> camps;
  final List<Cattle> cattle;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.size,
    required this.camps,
    required this.cattle,
  });

  // Factory constructor from Firestore DocumentSnapshot (camps and cattle can be passed in)
  factory Farm.fromSnapshot(DocumentSnapshot doc,
      {List<Camp> camps = const [], List<Cattle> cattle = const []}) {
    final data = doc.data() as Map<String, dynamic>;
    return Farm(
      id: doc.id,
      name: data['name'] ?? UNKNOWN,
      location: data['location'] ?? NOWHERE,
      type: data['type'] ?? UNKNOWN,
      size: data['size'] ?? 0,
      camps: camps,
      cattle: cattle,
    );
  }
}

class Camp {
  final String id;
  final String name;
  final GeoPoint location;
  final int size;

  Camp({
    required this.id,
    required this.name,
    required this.location,
    required this.size,
  });

  // Factory constructor from Firestore DocumentSnapshot
  factory Camp.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Camp(
      id: doc.id,
      name: data['name'] ?? UNKNOWN,
      location: data['location'] ?? NOWHERE,
      size: data['size'] ?? 0,
    );
  }
}
