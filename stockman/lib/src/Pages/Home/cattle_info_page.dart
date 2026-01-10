import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/models/cattle_profile.dart';
import 'package:stockman/src/models/weight_log.dart';
import 'package:stockman/src/models/treatment_log.dart';
import 'package:stockman/src/providers/cattle_db_service.dart';
import 'package:stockman/src/providers/weight_log_db_service.dart';
import 'package:stockman/src/providers/treatment_log_db_service.dart';

class CattleInfoPage extends StatefulWidget {
  final Cattle cattle;
  final VoidCallback refreshCattleData;

  const CattleInfoPage({
    super.key,
    required this.cattle,
    required this.refreshCattleData,
  });

  @override
  _CattleInfoPageState createState() => _CattleInfoPageState();
}

class _CattleInfoPageState extends State<CattleInfoPage> {
  final CattleDbService _dbService = CattleDbService();
  final WeightLogDbService _weightLogService = WeightLogDbService();
  final TreatmentLogDbService _treatmentLogService = TreatmentLogDbService();
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;
  bool _isLoading = false;

  // Controllers for editable fields
  late TextEditingController _tagNumberController;
  late TextEditingController _birthDateController;
  late TextEditingController _weanDateController;
  late TextEditingController _weanWeightController;
  late TextEditingController _groupNameController;
  late TextEditingController _noteController;

  String? _selectedTagColor;
  String? _selectedSex;
  String _selectedStatus = 'alive';
  String _selectedCurrentPregnancyStatus = 'unknown';
  Map<String, double> _breed = {};
  DateTime? _birthDate;
  DateTime? _weanDate;

  List<WeightLog> _weightLogs = [];
  List<TreatmentLog> _treatmentLogs = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadLogs();
  }

  void _initializeControllers() {
    _tagNumberController = TextEditingController(text: widget.cattle.tagNumber);
    _birthDateController = TextEditingController(
        text: widget.cattle.birthDate?.toString().split(' ')[0] ?? '');
    _weanDateController = TextEditingController(
        text: widget.cattle.weanDate?.toString().split(' ')[0] ?? '');
    _weanWeightController =
        TextEditingController(text: widget.cattle.weanWeight?.toString() ?? '');
    _groupNameController =
        TextEditingController(text: widget.cattle.groupName ?? '');
    _noteController = TextEditingController(text: widget.cattle.note ?? '');

    // Capitalize first letter of tag color to match dropdown items
    _selectedTagColor = widget.cattle.tagColour != null
        ? widget.cattle.tagColour![0].toUpperCase() +
            widget.cattle.tagColour!.substring(1).toLowerCase()
        : null;
    _selectedSex = widget.cattle.sex;
    _selectedStatus = widget.cattle.status;
    _selectedCurrentPregnancyStatus = widget.cattle.currentPregnancyStatus;
    _birthDate = widget.cattle.birthDate;
    _weanDate = widget.cattle.weanDate;

    if (widget.cattle.breed != null) {
      _breed = Map<String, double>.from(widget.cattle.breed!
          .map((key, value) => MapEntry(key, value.toDouble())));
    }
  }

  Future<void> _loadLogs() async {
    try {
      final weightLogs = await _weightLogService.getWeightLogs(
        cattleId: widget.cattle.id,
      );
      final treatmentLogs = await _treatmentLogService.getTreatmentLogs(
        cattleId: widget.cattle.id,
      );

      setState(() {
        _weightLogs = weightLogs;
        _treatmentLogs = treatmentLogs;
      });
    } catch (e) {
      dlog('Error loading logs: $e');
    }
  }

  @override
  void dispose() {
    _tagNumberController.dispose();
    _birthDateController.dispose();
    _weanDateController.dispose();
    _weanWeightController.dispose();
    _groupNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isBull => _selectedSex?.toLowerCase() == 'bull';

  Future<void> _selectBirthDate() async {
    if (!_isEditMode) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
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
        _birthDateController.text = pickedDate.toString().split(' ')[0];
      });
    }
  }

  Future<void> _selectWeanDate() async {
    if (!_isEditMode) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _weanDate ?? DateTime.now(),
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
        _weanDate = pickedDate;
        _weanDateController.text = pickedDate.toString().split(' ')[0];
      });
    }
  }

  Future<void> _showBreedDialog() async {
    if (!_isEditMode) return;

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
                  items: ['Angus', 'Hereford', 'Brahman', 'Bonsmara', 'Other']
                      .map((breed) => DropdownMenuItem(
                            value: breed,
                            child: Text(breed),
                          ))
                      .toList(),
                  onChanged: (value) => selectedBreed = value,
                  validator: (value) =>
                      value == null ? 'Please select a breed' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: percentageController,
                  decoration: InputDecoration(
                    labelText: 'Percentage',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a percentage';
                    }
                    final percentage = double.tryParse(value);
                    if (percentage == null ||
                        percentage <= 0 ||
                        percentage > 100) {
                      return 'Enter a valid percentage (1-100)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (breedFormKey.currentState!.validate() &&
                    selectedBreed != null) {
                  setState(() {
                    _breed[selectedBreed!] =
                        double.parse(percentageController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeBreed(String breedName) {
    if (!_isEditMode) return;
    setState(() {
      _breed.remove(breedName);
    });
  }

  Future<void> _saveCattleInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCattle = Cattle(
        id: widget.cattle.id,
        tagNumber: _tagNumberController.text.trim(),
        tagColour: _selectedTagColor,
        sex: _selectedSex,
        breed: _breed.isEmpty ? null : _breed,
        birthDate: _birthDate,
        weanDate: _weanDate,
        weanWeight: _weanWeightController.text.isNotEmpty
            ? double.tryParse(_weanWeightController.text)
            : null,
        groupName: _groupNameController.text.trim().isEmpty
            ? null
            : _groupNameController.text.trim(),
        campId: widget.cattle.campId,
        farmId: widget.cattle.farmId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        status: _selectedStatus,
        currentPregnancyStatus: _selectedCurrentPregnancyStatus,
      );

      await _dbService.updateCattle(
        cattleId: widget.cattle.id,
        cattle: updatedCattle,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cattle information updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.refreshCattleData();
        setState(() {
          _isEditMode = false;
        });
      }
    } catch (e) {
      dlog('Error updating cattle: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update cattle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateAge() {
    if (_birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - _birthDate!.year;
    if (today.month < _birthDate!.month ||
        (today.month == _birthDate!.month && today.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  String _getAgeDisplay() {
    if (_birthDate == null) return 'Unknown';
    final today = DateTime.now();
    final difference = today.difference(_birthDate!);
    final days = difference.inDays;

    if (days < 365) {
      return '$days days';
    } else {
      final years = days / 365.25;
      return '${years.toStringAsFixed(1)} years';
    }
  }

  double? _getCurrentWeight() {
    if (_weightLogs.isEmpty) return null;
    return _weightLogs.last.weight;
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
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Cattle' : 'Cattle Information',
          style: TextColorTheme.heading,
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          if (_isEditMode) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                  _initializeControllers();
                });
              },
              child: const Text('Cancel', style: TextStyle(color: darkGreen)),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveCattleInfo,
              child: const Text('Save',
                  style:
                      TextStyle(color: darkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 20),

                    // Identification Section
                    _buildSectionHeader('Identification'),
                    _buildInfoCard(
                      children: [
                        _buildTextFormField(
                          controller: _tagNumberController,
                          label: 'Tag Number',
                          enabled: _isEditMode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tag number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _isEditMode
                            ? DropdownButtonFormField<String>(
                                value: _selectedTagColor,
                                decoration: InputDecoration(
                                  labelText: 'Tag Color',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                items: ['Red', 'Yellow', 'Blue', 'Green']
                                    .map((color) => DropdownMenuItem(
                                          value: color,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
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
                              )
                            : _buildReadOnlyField(
                                label: 'Tag Color',
                                value: _selectedTagColor ?? 'Not set',
                                trailing: _selectedTagColor != null
                                    ? Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: _getColorFromString(
                                              _selectedTagColor!),
                                          shape: BoxShape.circle,
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                      )
                                    : null,
                              ),
                        const SizedBox(height: 16),
                        _isEditMode
                            ? DropdownButtonFormField<String>(
                                value: _selectedSex,
                                decoration: InputDecoration(
                                  labelText: 'Sex',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                items: ['Bull', 'Cow', 'Heifer', 'Steer']
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
                                validator: (value) =>
                                    value == null ? 'Please select sex' : null,
                              )
                            : _buildReadOnlyField(
                                label: 'Sex',
                                value: _selectedSex ?? 'Not set',
                              ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _groupNameController,
                          label: 'Group',
                          enabled: _isEditMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Breed Information
                    _buildSectionHeader('Breed Composition'),
                    _buildInfoCard(
                      children: [
                        if (_isEditMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _showBreedDialog,
                              icon: const Icon(Icons.add, color: darkGreen),
                              label: const Text('Add Breed',
                                  style: TextStyle(color: darkGreen)),
                            ),
                          ),
                        if (_breed.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No breed information',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ..._breed.entries.map((entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${entry.key}: ${entry.value.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    if (_isEditMode)
                                      IconButton(
                                        onPressed: () =>
                                            _removeBreed(entry.key),
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Birth & Growth Information
                    _buildSectionHeader('Birth & Growth'),
                    _buildInfoCard(
                      children: [
                        _isEditMode
                            ? GestureDetector(
                                onTap: _selectBirthDate,
                                child: AbsorbPointer(
                                  child: _buildTextFormField(
                                    controller: _birthDateController,
                                    label: 'Birth Date',
                                    enabled: true,
                                  ),
                                ),
                              )
                            : _buildReadOnlyField(
                                label: 'Birth Date',
                                value: _birthDate?.toString().split(' ')[0] ??
                                    'Not set',
                              ),
                        if (_birthDate != null) ...[
                          const SizedBox(height: 16),
                          _buildReadOnlyField(
                            label: 'Age',
                            value: _getAgeDisplay(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _isEditMode
                            ? GestureDetector(
                                onTap: _selectWeanDate,
                                child: AbsorbPointer(
                                  child: _buildTextFormField(
                                    controller: _weanDateController,
                                    label: 'Wean Date',
                                    enabled: true,
                                  ),
                                ),
                              )
                            : (_weanDate != null
                                ? _buildReadOnlyField(
                                    label: 'Wean Date',
                                    value: _weanDate.toString().split(' ')[0],
                                  )
                                : const SizedBox.shrink()),
                        if (_isEditMode || _weanDate != null)
                          const SizedBox(height: 16),
                        if (_isEditMode ||
                            (_weanWeightController.text.isNotEmpty &&
                                double.tryParse(_weanWeightController.text) !=
                                    null))
                          _buildTextFormField(
                            controller: _weanWeightController,
                            label: 'Wean Weight (kg)',
                            enabled: _isEditMode,
                            keyboardType: TextInputType.number,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Information
                    _buildSectionHeader('Status'),
                    _buildInfoCard(
                      children: [
                        _isEditMode
                            ? DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                items: ['alive', 'sold', 'dead']
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status.toUpperCase()),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                              )
                            : _buildReadOnlyField(
                                label: 'Status',
                                value: _selectedStatus.toUpperCase(),
                              ),
                        if (!_isBull) ...[
                          const SizedBox(height: 16),
                          _isEditMode
                              ? DropdownButtonFormField<String>(
                                  value: _selectedCurrentPregnancyStatus,
                                  decoration: InputDecoration(
                                    labelText: 'Pregnancy Status',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  items: [
                                    'unknown',
                                    'pregnant',
                                    'not_pregnant',
                                    'calved'
                                  ]
                                      .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status
                                                .replaceAll('_', ' ')
                                                .toUpperCase()),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCurrentPregnancyStatus = value!;
                                    });
                                  },
                                )
                              : _buildReadOnlyField(
                                  label: 'Pregnancy Status',
                                  value: _selectedCurrentPregnancyStatus
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Weight History
                    _buildSectionHeader('Weight History'),
                    _buildWeightLogsSection(),
                    const SizedBox(height: 20),

                    // Treatment History
                    _buildSectionHeader('Treatment History'),
                    _buildTreatmentLogsSection(),
                    const SizedBox(height: 20),

                    // Notes
                    _buildSectionHeader('Notes'),
                    _buildInfoCard(
                      children: [
                        _buildTextFormField(
                          controller: _noteController,
                          label: 'Additional Notes',
                          enabled: _isEditMode,
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final age = _calculateAge();
    final currentWeight = _getCurrentWeight();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            _tagNumberController.text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: baige,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Age', _getAgeDisplay()),
              _buildSummaryItem('Sex', _selectedSex ?? 'Not set'),
              _buildSummaryItem(
                  'Weight',
                  currentWeight != null
                      ? '${currentWeight.toStringAsFixed(0)} kg'
                      : 'No data'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: baige,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: baige,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightLogsSection() {
    return _buildInfoCard(
      children: [
        if (_weightLogs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No weight records available',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
        else
          Column(
            children: _weightLogs.reversed.take(5).map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.date.toString().split(' ')[0],
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${log.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_weightLogs.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '+ ${_weightLogs.length - 5} more records',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTreatmentLogsSection() {
    return _buildInfoCard(
      children: [
        if (_treatmentLogs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No treatment records available',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          )
        else
          Column(
            children: _treatmentLogs.reversed.take(5).map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            log.treatmentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          log.date.toString().split(' ')[0],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (log.dosage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Dosage: ${log.dosage}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    if (log.notes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          log.notes!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const Divider(height: 16),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_treatmentLogs.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '+ ${_treatmentLogs.length - 5} more records',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
