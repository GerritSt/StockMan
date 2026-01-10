import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/providers/weight_log_db_service.dart';
import 'package:stockman/src/providers/cattle_document_db_service.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/models/weight_log.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:file_picker/file_picker.dart';

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
  final WeightLogDbService _weightLogService = WeightLogDbService();
  final CattleDocumentDbService _documentService = CattleDocumentDbService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tagNumberController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _weanDateController = TextEditingController();
  final TextEditingController _weanWeightController = TextEditingController();
  final TextEditingController _initialWeightController =
      TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedTagColor;
  String? _selectedSex;
  String _selectedStatus = 'alive';
  final Map<String, double> _breed = {};
  DateTime? _birthDate;
  DateTime? _weanDate;
  DateTime? _initialWeightDate;
  String _groupName = 'Group 1';
  bool _isLoading = false;
  bool _hasBeenWeaned = false;
  bool _addInitialWeight = false;
  final List<File> _selectedDocuments = [];
  final List<String> _documentTitles = [];

  @override
  void dispose() {
    _tagNumberController.dispose();
    _birthDateController.dispose();
    _weanDateController.dispose();
    _weanWeightController.dispose();
    _initialWeightController.dispose();
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

  Future<void> _selectWeanDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: _birthDate ?? DateTime(1950),
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
        _weanDate = pickedDate;
        _weanDateController.text = pickedDate.toString().split(" ")[0];
      });
    }
  }

  Future<void> _pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _selectedDocuments.add(File(file.path!));
              _documentTitles.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      dlog('Error picking documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _selectedDocuments.removeAt(index);
      _documentTitles.removeAt(index);
    });
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

    // Validate breed composition totals 100% if any breeds are added
    if (_breed.isNotEmpty) {
      final total = _breed.values.fold<double>(0, (sum, val) => sum + val);
      if (total != 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Breed composition must total 100%. Current total: ${total.toStringAsFixed(0)}%'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Validate wean date is at least 12 days after birth date
    if (_hasBeenWeaned && _weanDate != null && _birthDate != null) {
      final difference = _weanDate!.difference(_birthDate!).inDays;
      if (difference < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Wean date must be at least 12 days after birth date. Current difference: $difference days'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
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
        weanDate: _hasBeenWeaned ? _weanDate : null,
        weanWeight: _hasBeenWeaned && _weanWeightController.text.isNotEmpty
            ? double.tryParse(_weanWeightController.text)
            : null,
        groupName: _groupName,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        status: _selectedStatus,
        currentPregnancyStatus: 'unknown',
      );

      final cattleId = await _dbService.addCattle(
        farmId: widget.farmId,
        campId: widget.campId,
        cattle: cattle,
      );

      // Add initial weight log if provided
      if (_addInitialWeight && _initialWeightController.text.isNotEmpty) {
        final weight = double.tryParse(_initialWeightController.text);
        if (weight != null) {
          final weightLog = WeightLog(
            id: '',
            cattleId: cattleId,
            date: _initialWeightDate ?? DateTime.now(),
            weight: weight,
          );
          await _weightLogService.addWeightLog(weightLog: weightLog);
        }
      }

      // Upload cattle documents if any
      List<String> failedDocuments = [];
      if (_selectedDocuments.isNotEmpty) {
        for (int i = 0; i < _selectedDocuments.length; i++) {
          try {
            await _documentService.uploadDocument(
              farmId: widget.farmId,
              cattleId: cattleId,
              file: _selectedDocuments[i],
              documentType: 'branding',
              title: _documentTitles[i],
            );
            dlog('Document uploaded successfully: ${_documentTitles[i]}');
          } catch (e) {
            dlog('Error uploading document ${_documentTitles[i]}: $e');
            failedDocuments.add(_documentTitles[i]);
          }
        }
      }

      if (!mounted) return;

      widget.refreshCattleData();
      Navigator.of(context).pop();

      // Show appropriate success message
      if (failedDocuments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cattle added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cattle added, but ${failedDocuments.length} document(s) failed to upload. Check storage permissions.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
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
        title: const Text(
          'Add New Cattle',
          style: TextColorTheme.heading,
        ),
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
                    _buildSectionTitle('📋 Basic Information'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _tagNumberController,
                            decoration: _inputDecoration(
                              'Tag Number',
                              'e.g. ABC-123',
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
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'alive',
                                label: Text('Active'),
                              ),
                              ButtonSegment(
                                value: 'sold',
                                label: Text('Sold'),
                              ),
                              ButtonSegment(
                                value: 'dead',
                                label: Text('Dead'),
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
                    _buildSectionTitle('Birth & Weight Information'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _birthDateController,
                            decoration: _inputDecoration(
                              '📅 Birth Date',
                              'Select date',
                            ).copyWith(
                              suffixIcon: const Icon(Icons.calendar_today,
                                  color: darkGreen),
                            ),
                            readOnly: true,
                            onTap: _selectBirthDate,
                          ),
                          const SizedBox(height: 16),
                          // Has Been Weaned Checkbox
                          CheckboxListTile(
                            title: const Text(
                              'Has been weaned',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            value: _hasBeenWeaned,
                            onChanged: (value) {
                              setState(() {
                                _hasBeenWeaned = value ?? false;
                                if (!_hasBeenWeaned) {
                                  _weanDate = null;
                                  _weanDateController.clear();
                                  _weanWeightController.clear();
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: darkGreen,
                          ),
                          if (_hasBeenWeaned) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weanDateController,
                              decoration: _inputDecoration(
                                '📅 Wean Date',
                                'Select date',
                              ).copyWith(
                                suffixIcon: const Icon(Icons.calendar_today,
                                    color: darkGreen),
                              ),
                              readOnly: true,
                              onTap: _selectWeanDate,
                              validator: (value) {
                                if (_hasBeenWeaned &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please select wean date';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weanWeightController,
                              decoration: _inputDecoration(
                                'Wean Weight (kg)',
                                'e.g. 180',
                              ).copyWith(
                                suffixIcon: const Icon(
                                    Icons.monitor_weight_outlined,
                                    color: darkGreen),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_hasBeenWeaned &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter wean weight';
                                }
                                if (_hasBeenWeaned) {
                                  final weight = double.tryParse(value!);
                                  if (weight == null ||
                                      weight <= 0 ||
                                      weight > 1000) {
                                    return 'Enter a valid weight (1-1000 kg)';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Initial Weight Section
                          CheckboxListTile(
                            title: const Text(
                              'Add initial weight',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            value: _addInitialWeight,
                            onChanged: (value) {
                              setState(() {
                                _addInitialWeight = value ?? false;
                                if (!_addInitialWeight) {
                                  _initialWeightController.clear();
                                  _initialWeightDate = null;
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: darkGreen,
                          ),
                          if (_addInitialWeight) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _initialWeightController,
                              decoration: _inputDecoration(
                                'Weight (kg)',
                                'e.g. 250',
                              ).copyWith(
                                suffixIcon: const Icon(
                                    Icons.monitor_weight_outlined,
                                    color: darkGreen),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (_addInitialWeight &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter weight';
                                }
                                if (_addInitialWeight) {
                                  final weight = double.tryParse(value!);
                                  if (weight == null ||
                                      weight <= 0 ||
                                      weight > 1500) {
                                    return 'Enter a valid weight (1-1500 kg)';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Weight will be recorded with today\'s date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('🐄 Breed Information'),
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
                    _buildSectionTitle('📝 Additional Notes'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: TextFormField(
                        controller: _noteController,
                        decoration: _inputDecoration(
                          'Notes',
                          'Add any additional information...',
                        ),
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cattle Documents Section
                    _buildSectionTitle('📄 Branding Documents (Optional)'),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedDocuments.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.description_outlined,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No documents added',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: List.generate(
                                _selectedDocuments.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.insert_drive_file,
                                      color: darkGreen,
                                    ),
                                    title: Text(
                                      _documentTitles[index],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () => _removeDocument(index),
                                    ),
                                    tileColor: Colors.grey[50],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickDocuments,
                              icon: const Icon(Icons.upload_file),
                              label:
                                  const Text('Add Documents (PDF, JPG, PNG)'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: darkGreen),
                                foregroundColor: darkGreen,
                              ),
                            ),
                          ),
                        ],
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
          color: Theme.of(context).appBarTheme.backgroundColor,
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
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
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
                    : const Text(
                        'Add Cattle',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkGreen,
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

  InputDecoration _inputDecoration(String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
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
