import 'package:flutter/material.dart';
import 'package:stockman/src/config/constants.dart';

class ChangeslogPage extends StatefulWidget {
  const ChangeslogPage({super.key});

  @override
  State<ChangeslogPage> createState() => _ChangeslogPageState();
}

class _ChangeslogPageState extends State<ChangeslogPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(COMINGSOON),
    );
  }
}
