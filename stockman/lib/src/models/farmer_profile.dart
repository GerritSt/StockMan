import 'package:stockman/src/models/cattle_profile.dart';

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

class Farmer {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final GeoPoint location;
  final List<Farm> farms;
  final String? profileImageUrl;

  Farmer({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.location,
    required this.farms,
    this.profileImageUrl,
  });

  factory Farmer.fromJson(Map<String, dynamic> json,
      {List<Farm> farms = const []}) {
    // Location field removed from database, use default NOWHERE
    return Farmer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: const GeoPoint(0, 0), // Not stored in database
      farms: farms,
      profileImageUrl: json['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'surname': surname,
        'email': email,
        'phone': phone,
        'profile_image_url': profileImageUrl,
        // Location field removed from database
      };
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

  factory Farm.fromJson(Map<String, dynamic> json,
      {List<Camp> camps = const [], List<Cattle> cattle = const []}) {
    final locationStr = json['location'] ?? '0,0';
    final parts = locationStr.split(',');
    final location = parts.length == 2
        ? GeoPoint(
            double.tryParse(parts[0]) ?? 0, double.tryParse(parts[1]) ?? 0)
        : const GeoPoint(0, 0);

    return Farm(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: location,
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      camps: camps,
      cattle: cattle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': '${location.latitude},${location.longitude}',
        'type': type,
        'size': size,
      };
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

  factory Camp.fromJson(Map<String, dynamic> json) {
    final locationStr = json['location'] ?? '0,0';
    final parts = locationStr.split(',');
    final location = parts.length == 2
        ? GeoPoint(
            double.tryParse(parts[0]) ?? 0, double.tryParse(parts[1]) ?? 0)
        : const GeoPoint(0, 0);

    return Camp(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: location,
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': '${location.latitude},${location.longitude}',
        'size': size,
      };
}
