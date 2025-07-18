import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockman/src/models/cattle_profile.dart';

class Farmer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final GeoPoint location;
  final List<Farm> farms;

  Farmer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.farms,
  });
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
}
