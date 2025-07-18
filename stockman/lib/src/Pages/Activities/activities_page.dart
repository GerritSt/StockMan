import 'package:flutter/material.dart';
import 'package:stockman/src/config/text_theme.dart';

// ignore: must_be_immutable
class ActivitiesPage extends StatelessWidget {
  ActivitiesPage({super.key});

  List<Widget> buttonsList = [
    const ActivitiesButton(Icons.scale, 'Weigh'),
    const ActivitiesButton(Icons.medical_services, 'Treatment'),
    const ActivitiesButton(Icons.upgrade, 'Upgrade calf'),
    const ActivitiesButton(Icons.all_inclusive, 'Wean Calves'),
    const ActivitiesButton(Icons.view_compact, 'Manage Groups'),
    const ActivitiesButton(Icons.grass, 'Grazing management'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(title: const Text('Activities', style: TextColorTheme.heading,),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body:ListView(children: buttonsList),
    );
  }
}

// Class for the buttons in the activities page
class ActivitiesButton extends StatelessWidget {
  const ActivitiesButton(this.activityIcon, this.buttonLabel, {super.key});
  final IconData activityIcon;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return  Padding(
        padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
        child: ElevatedButton(
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 13, top: 5, bottom: 5),
                  child: Icon(activityIcon, size: 40),
                ),
                Text(buttonLabel, style: TextColorTheme.inAppText,),
              ],
            )),
    );
  }
}
