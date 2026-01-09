import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/config/constants.dart';

class AddCattlePage extends StatefulWidget {
  final String farmerId;
  final String farmId;
  final String campId;
  final VoidCallback refreshCattleData;

  const AddCattlePage({
    super.key,
    required this.farmerId,
    required this.farmId,
    required this.campId,
    required this.refreshCattleData,
  });

  @override
  _AddCattlePageState createState() => _AddCattlePageState();
}

class _AddCattlePageState extends State<AddCattlePage> {
  final CattleDbService _dbService = CattleDbService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tagNumberController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedTagColor;
  String? _selectedSex;
  String _selectedStatus = 'alive';
  final Map<String, double> _breed = {};
  DateTime? _birthDate;
  String _groupName = 'Group 1';
  bool _isLoading = false;

  @override
  void dispose() {
    _tagNumberController.dispose();
    _birthDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: darkGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _birthDate = pickedDate;
        _birthDateController.text = pickedDate.toString().split(" ")[0];
      });
    }
  }

  Future<void> _showBreedDialog() async {
    final breedFormKey = GlobalKey<FormState>();
    String? selectedBreed;
    final percentageController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Breed',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: breedFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Breed',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.pets),
                  ),
                  items: cattleBreeds.map((breed) {
                    return DropdownMenuItem<String>(
                      value: breed,
                      child: Text(breed),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedBreed = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a breed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: percentageController,
                  decoration: InputDecoration(
                    labelText: 'Percentage (%)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.percent),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final percentage = double.tryParse(value ?? '');
                    if (percentage == null ||
                        percentage <= 0 ||
                        percentage > 100) {
                      return 'Enter a value between 1 and 100';
                    }
                    final currentTotal =
                        _breed.values.fold<double>(0, (sum, val) => sum + val);
                    if (currentTotal + percentage > 100) {
                      return 'Total exceeds 100% (current: ${currentTotal.toStringAsFixed(0)}%)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (breedFormKey.currentState!.validate()) {
                  final percentage = double.parse(percentageController.text);
                  setState(() {
                    _breed[selectedBreed!] = percentage;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCattle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tagNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tag number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cattle = Cattle(
        id: '',
        tagNumber: _tagNumberController.text.trim(),
        tagColour: _selectedTagColor,
        sex: _selectedSex,
        breed: _breed.isNotEmpty ? Map<String, dynamic>.from(_breed) : null,
        birthDate: _birthDate,
        weanDate: null,
        weanWeight: null,
        groupName: _groupName,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        status: _selectedStatus,
        pregnancy: 'unknown',
      );

      await _dbService.addCattle(
        farmId: widget.farmId,
        campId: widget.campId,
        cattle: cattle,
      );

      if (mounted) {
        widget.refreshCattleData();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cattle added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      dlog('Error adding cattle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding cattle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baige,
      appBar: AppBar(
        title: const Text('Add New Cattle'),
        elevation: 0,
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _tagNumberController,
                            decoration: _inputDecoration(
                              'Tag Number',
                              'e.g. ABC-123',
                              Icons.local_offer,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tag number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTagColor,
                                  decoration: _inputDecoration(
                                    'Tag Color',
                                    'Select color',
                                    Icons.palette,
                                  ),
                                  items: [
                                    'Red',
                                    'Yellow',
                                    'Blue',
                                    'Green',
                                    'White',
                                    'Orange'
                                  ]
                                      .map((color) => DropdownMenuItem(
                                            value: color.toLowerCase(),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: _getColorFromString(
                                                        color),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(color),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTagColor = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSex,
                                  decoration: _inputDecoration(
                                    'Sex',
                                    'Select sex',
                                    Icons.wc,
                                  ),
                                  items:
                                      ['Bull', 'Cow', 'Steer', 'Heifer', 'Calf']
                                          .map((sex) => DropdownMenuItem(
                                                value: sex,
                                                child: Text(sex),
                                              ))
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSex = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _birthDateController,
                            decoration: _inputDecoration(
                              'Birth Date',
                              'Select date',
                              Icons.calendar_today,
                            ),
                            readOnly: true,
                            onTap: _selectBirthDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Status & Group'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'alive',
                                label: Text('Active'),
                                icon: Icon(Icons.check_circle_outline),
                              ),
                              ButtonSegment(
                                value: 'sold',
                                label: Text('Sold'),
                                icon: Icon(Icons.sell_outlined),
                              ),
                              ButtonSegment(
                                value: 'dead',
                                label: Text('Dead'),
                                icon: Icon(Icons.block),
                              ),
                            ],
                            selected: {_selectedStatus},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedStatus = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return darkGreen;
                                  }
                                  return Colors.white;
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return Colors.black87;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _groupName,
                            decoration: _inputDecoration(
                              'Group',
                              'Select group',
                              Icons.group,
                            ),
                            items: List.generate(
                                    10, (index) => 'Group ${index + 1}')
                                .map((group) => DropdownMenuItem(
                                      value: group,
                                      child: Text(group),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _groupName = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Breed Information'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Breed Composition',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (_breed.isNotEmpty)
                                Text(
                                  '${_breed.values.fold<double>(0, (sum, val) => sum + val).toStringAsFixed(0)}% Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_breed.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No breeds added yet',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _breed.entries.map((entry) {
                                return Chip(
                                  label: Text(
                                      '${entry.key}: ${entry.value.toStringAsFixed(0)}%'),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    setState(() {
                                      _breed.remove(entry.key);
                                    });
                                  },
                                  backgroundColor: darkGreen.withOpacity(0.1),
                                  deleteIconColor: darkGreen,
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _breed.values.fold<double>(
                                          0, (sum, val) => sum + val) >=
                                      100
                                  ? null
                                  : _showBreedDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Breed'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: darkGreen,
                                side: BorderSide(color: darkGreen),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Additional Notes'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: TextFormField(
                        controller: _noteController,
                        decoration: _inputDecoration(
                          'Notes',
                          'Add any additional information...',
                          Icons.notes,
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCattle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Add Cattle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(
      String labelText, String hintText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: darkGreen),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: darkGreen, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'white':
        return Colors.white;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
