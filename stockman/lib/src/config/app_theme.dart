import 'package:flutter/material.dart';

const Color darkGreen = Color.fromARGB(255, 53, 68, 34);
const Color baige = Color.fromARGB(255, 239, 225, 203);

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ),
        scaffoldBackgroundColor: baige,
        appBarTheme: AppBarTheme(
          backgroundColor: baige,
          foregroundColor: Color.fromARGB(255, 6, 65, 8),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkGreen,
          indicatorColor: Color.fromARGB(49, 62, 60, 9),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: baige);
            }
            return const IconThemeData(color: Colors.green);
          }),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: Colors.white,
          textColor: Colors.white,
          tileColor: darkGreen,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkGreen,
          foregroundColor: baige,
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: Colors.lightGreen,
          ), 
        ));
  }
}
