import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:numberpicker/numberpicker.dart'; // Add this line
import 'package:cloud_firestore/cloud_firestore.dart';

enum Status { active, sold, dead }

class AddCattlePage extends StatefulWidget {
  final String farmerId;
  final String farmId;
  final String campId;
  final VoidCallback refreshCattleData;
  const AddCattlePage({super.key, required this.farmerId, required this.farmId, required this.campId, required this.refreshCattleData});

  @override
  // ignore: library_private_types_in_public_api
  _AddCattlePageState createState() => _AddCattlePageState();
}

class _AddCattlePageState extends State<AddCattlePage> {
  final CattleDbService _dbService = CattleDbService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _cattleData = {};
  final Map<String, dynamic> _breed = {};
  final TextEditingController _dateController = TextEditingController();
  final _percentageController = TextEditingController();
  Status _status = Status.active;
  final Map<String, double> _weight = {}; // Change DateTime to String
  int _group = 1; // Add this line

  // TODO: Replace these with actual logic to get the current user's IDs
  // final String farmerId = 'demoFarmerId';
  // final String farmId = 'demoFarmId';
  // final String campId = 'demoCampId';

  Future<void> _selectDate(BuildContext context, String key) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      _dateController.text = pickedDate.toString().split(" ")[0];
      _cattleData['birthdate'] = pickedDate.toIso8601String();
    }
  }

  // breed map => {breed1:{angus: 50}, breed2:{charolais: 50}}
  Future<void> _showBreedPercentageDialog(BuildContext context) async {
    final breedFormKey = GlobalKey<FormState>();
    String? breedVar = '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Breed Percentage'),
          content: Form(
            key: breedFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Breed'),
                  items: cattleBreeds.map((label) {
                    return DropdownMenuItem<String>(
                      value: label,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      breedVar = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a breed';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _percentageController,
                  decoration: InputDecoration(labelText: 'Percentage'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final percentage = double.tryParse(value ?? '');
                    if (percentage == null ||
                        percentage < 1 ||
                        percentage > 100) {
                      return 'Percentage between 0 and 100';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                if (breedFormKey.currentState!.validate()) {
                  final percentage =
                      double.tryParse(_percentageController.text) ?? 0.0;
                  if (breedVar!.isNotEmpty && percentage > 0) {
                    setState(() {
                      _breed[breedVar!] = percentage;
                    });
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // weight map => {weight1:{2021-09-01, 100.0}, weight2:{2021-09-02, 101.0}}
  Future<void> _showDateWeightDialog(BuildContext context) async {
    final weightFormKey = GlobalKey<FormState>();
    String? dateVar;
    double? weightVar = 0.0;
    _dateController.clear();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Weight Log'),
          content: Form(
            key: weightFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(labelText: 'Date'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        dateVar = pickedDate.toString().split(" ")[0];
                        _dateController.text = dateVar!;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Weight'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final weight = double.tryParse(value ?? '');
                    if (weight == null || weight <= 0 || weight > 1000) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    weightVar = double.tryParse(value);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () {
                if (weightFormKey.currentState!.validate()) {
                  setState(() {
                    _weight[dateVar!] = weightVar!;
                    // add the _weight map to the _cattleData map
                    _cattleData['weight'] = _weight;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Cattle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 4),
                // tag number
                TextFormField(
                  decoration: _inputDecoration('Tag Number', 'e.g. aBc-12_3'),
                  onSaved: (value) {
                    _cattleData['tag'] = value;
                  },
                ),
                SizedBox(height: 10),
                // tag colour
                Row(
                  children: [
                    _dropdownMenu('Tag color',
                        ['red', 'yellow', 'blue', 'green'], 'tagColor'),
                    SizedBox(width: 10),
                    // Sex
                    _dropdownMenu(
                        'Sex', ['Cow', 'Bull', 'Calf', 'Steer'], 'sex'),
                  ],
                ),
                SizedBox(height: 10),
                // status
                SegmentedButton<Status>(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.symmetric(horizontal: 4),
                  segments: [
                    ButtonSegment(
                      value: Status.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment(
                      value: Status.sold,
                      label: Text('Sold'),
                    ),
                    ButtonSegment(
                      value: Status.dead,
                      label: Text('Dead'),
                    ),
                  ],
                  onSelectionChanged: (Set<Status> newStatus) {
                    setState(() {
                      _status = newStatus.first;
                    });
                  },
                  selected: <Status>{_status},
                ),
                SizedBox(height: 10),
                // breed
                Row(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7))),
                      ),
                      onPressed: () => _showBreedPercentageDialog(context),
                      child: Text('Add Breed:'),
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 50,
                      width: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: OverflowBox(
                          maxHeight: 50,
                          minHeight: 20,
                          child: SingleChildScrollView(
                            child: Column(
                              children: _breed.entries.map(
                                (entry) {
                                  return ListTile(
                                    tileColor: baige,
                                    textColor: Colors.black,
                                    onTap: () {
                                      setState(() {
                                        _breed.remove(entry.key);
                                      });
                                    },
                                    title:
                                        Text('${entry.key}: ${entry.value}%'),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // birthdate
                TextFormField(
                  controller: _dateController,
                  decoration: _inputDecoration('Birthdate', ''),
                  readOnly: true,
                  onSaved: (value) {
                    _cattleData['birthdate'] = value;
                  },
                  onTap: () => _selectDate(context, 'birthdate'),
                ),
                SizedBox(height: 10),
                // weight
                // add the weight button and list of weights here
                Row(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7))),
                      ),
                      onPressed: () => _showDateWeightDialog(context),
                      child: Text('Add Weight:'),
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 50,
                      width: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white),
                        color: baige,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: _weight.entries.map(
                            (entry) {
                              return ListTile(
                                tileColor: baige,
                                textColor: Colors.black,
                                onTap: () {
                                  setState(() {
                                    _weight.remove(entry.key);
                                  });
                                },
                                title: Text(
                                    '${entry.key}: ${entry.value} kg'),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Group
                Row(
                  children: [
                    Text(
                      'Group:',
                      style: TextColorTheme.inAppText,
                    ),
                    SizedBox(width: 10),
                    Container(
                      width: 100, // Set a fixed width to make it smaller
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white), // Add a white border
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40, // Adjust the width of the IconButton
                            child: IconButton(
                              icon: Icon(Icons.remove,
                                  size: 20), // Adjust the icon size
                              onPressed: () {
                                setState(() {
                                  if (_group > 1) _group--;
                                  _cattleData['group'] = _group;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: NumberPicker(
                              value: _group,
                              minValue: 1,
                              maxValue: 100,
                              itemHeight: 20,
                              itemWidth: 30, // Adjust the item width
                              onChanged: (value) {
                                setState(() {
                                  _group = value;
                                });
                                _cattleData['group'] = value;
                              },
                              textStyle: TextStyle(
                                  fontSize: 14), // Adjust text size if needed
                              selectedTextStyle: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(
                            width: 40, // Adjust the width of the IconButton
                            child: IconButton(
                              icon: Icon(Icons.add,
                                  size: 20), // Adjust the icon size
                              onPressed: () {
                                setState(() {
                                  if (_group < 100) _group++;
                                  _cattleData['group'] = _group;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // save and cancel buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          // Generate deterministic cattle ID
                          final birthDate = _cattleData['birthdate'] is String
                              ? DateTime.tryParse(_cattleData['birthdate']) ?? DateTime(1950, 1, 1)
                              : DateTime(1950, 1, 1);
                          final sex = _cattleData['sex'] ?? '';
                          final rand = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
                          final dateStr = " {birthDate.year.toString().padLeft(4, '0')} {birthDate.month.toString().padLeft(2, '0')} {birthDate.day.toString().padLeft(2, '0')}";
                          final cattleId = "${dateStr}_${sex}_$rand";
                          // Convert form data to Cattle object
                          final cattle = Cattle(
                            id: cattleId,
                            tag: _cattleData['tag'] ?? '',
                            birthDate: birthDate,
                            group: _cattleData['group'] ?? 0,
                            sex: sex,
                            breed: Map<String, double>.from(_breed),
                            weight: Map<String, dynamic>.from(_weight),
                            farm: <String, GeoPoint>{}, // Placeholder, update as needed
                            camp: <String, GeoPoint>{}, // Placeholder, update as needed
                          );
                          await _dbService.addCattle(
                            farmerId: widget.farmerId,
                            farmId: widget.farmId,
                            campId: widget.campId,
                            cattle: cattle,
                            cattleId: cattleId,
                          );
                          widget.refreshCattleData();
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText, String hintText) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      border: OutlineInputBorder(),
    );
  }

  Widget _dropdownMenu(String labelText, List<String> items, String key) {
    return DropdownMenu(
      enableFilter: true,
      label: Text(labelText),
      dropdownMenuEntries: items
          .map((label) => DropdownMenuEntry(
                label: label,
                value: label,
              ))
          .toList(),
      onSelected: (value) {
        _cattleData[key] = value;
      },
    );
  }
}

List<String> cattleBreeds = [
  'Afrikaner',
  'Angus',
  'Brahman',
  'Bonsmara',
  'Charolais',
  'Hereford',
  'Jersey',
  'Kalahari Red',
  'Simmental',
  'Drakensberger',
  'Nguni',
  'Shorthorn',
  'Friesian',
  'Holstein',
  'Dexter',
  'Limousin',
  'Saler',
  'Pinzgauer',
  'Red Poll',
  'Wagyu',
  'Beef Shorthorn',
  'Braford',
  'Blonde d\'Aquitaine',
  'Brangus',
  'Galloway',
  'Gloucester',
  'Lincoln Red',
  'Murray Grey',
  'Santa Gertrudis',
  'South Devon',
  'Tuli',
  'White Park',
  'Zebu',
];
