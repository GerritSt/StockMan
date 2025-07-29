// Here lies the constants

import 'package:cloud_firestore/cloud_firestore.dart';

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
