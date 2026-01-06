import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/widgets/gps_location_picker.dart';
import 'package:stockman/src/providers/camp_db_service.dart';

class CampFormPage extends StatefulWidget {
  final String farmId;
  final Camp? camp; // null for create, non-null for edit

  const CampFormPage({
    super.key,
    required this.farmId,
    this.camp,
  });

  @override
  State<CampFormPage> createState() => _CampFormPageState();
}

class _CampFormPageState extends State<CampFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sizeController;
  GeoPoint? _location;
  String? _locationAddress;
  bool _saving = false;

  bool get _isEditing => widget.camp != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.camp?.name ?? '');
    _sizeController = TextEditingController(
      text: widget.camp?.size != null ? widget.camp!.size.toString() : '',
    );
    _location = widget.camp?.location ?? const GeoPoint(0, 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GpsLocationPicker(
          initialLocation: _location,
          title: 'Camp Location',
          onLocationSelected: (location, address) {
            setState(() {
              _location = location;
              _locationAddress = address;
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveCamp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_location == null ||
        (_location!.latitude == 0 && _location!.longitude == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please set a location for the camp'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final camp = Camp(
        id: widget.camp?.id ?? '', // Will be set by database if creating
        name: _nameController.text.trim(),
        location: _location!,
        size: int.parse(_sizeController.text.trim()),
      );

      // Save camp to Supabase
      if (_isEditing) {
        await CampDbService().updateCamp(camp);
      } else {
        await CampDbService().createCamp(widget.farmId, camp);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Camp updated successfully!'
                  : 'Camp created successfully!',
            ),
            backgroundColor: darkGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving camp: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Camp' : 'Add New Camp',
          style: TextColorTheme.heading,
        ),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _saveCamp,
              child: Text(
                'Save',
                style: TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: darkGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fence,
                          size: 60,
                          color: darkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Camp Name
                    Text(
                      'Camp Name *',
                      style: TextColorTheme.heading.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a camp name';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., North Pasture, Camp 1',
                        prefixIcon: const Icon(Icons.fence),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Camp Size
                    Text(
                      'Camp Size (hectares) *',
                      style: TextColorTheme.heading.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sizeController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the camp size';
                        }
                        final size = int.tryParse(value);
                        if (size == null || size <= 0) {
                          return 'Please enter a valid size';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., 50',
                        prefixIcon: const Icon(Icons.square_foot),
                        suffixText: 'ha',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Location Section
                    Text(
                      'Location *',
                      style: TextColorTheme.heading.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GpsLocationField(
                      location: _location,
                      address: _locationAddress,
                      onTap: _showLocationPicker,
                      label: 'Camp Location',
                    ),

                    const SizedBox(height: 16),

                    // Helper Text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: darkGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: darkGreen.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: darkGreen.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Set the GPS coordinates for the camp\'s center or main gate.',
                              style: TextColorTheme.inAppText.copyWith(
                                fontSize: 12,
                                color: darkGreen.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveCamp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: baige,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Camp' : 'Create Camp',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cancel Button
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkGreen,
                        side: const BorderSide(color: darkGreen, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
