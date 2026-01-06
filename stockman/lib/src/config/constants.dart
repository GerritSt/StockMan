// Here lies the constants

// import 'package:cloud_firestore/cloud_firestore.dart';

// Import GeoPoint from farmer_profile instead
import 'package:stockman/src/models/farmer_profile.dart';

DateTime RANDOMDATE = DateTime(1950, 1, 1);
const GeoPoint NOWHERE = GeoPoint(0.0, 0.0);
const String UNKNOWN = 'Unknown';

const String COMINGSOON = 'Coming soon!';

const bool isDebugging = true;

// Debugging statements when the flag is enabled
void dlog(String message) {
  if (isDebugging) {
    print(message);
  }
}
