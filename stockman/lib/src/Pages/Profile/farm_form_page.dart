import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/widgets/gps_location_picker.dart';
import 'package:stockman/src/providers/farm_db_service.dart';

class FarmFormPage extends StatefulWidget {
  final String farmerId;
  final Farm? farm; // null for create, non-null for edit

  const FarmFormPage({
    super.key,
    required this.farmerId,
    this.farm,
  });

  @override
  State<FarmFormPage> createState() => _FarmFormPageState();
}

class _FarmFormPageState extends State<FarmFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _sizeController;
  GeoPoint? _location;
  String? _locationAddress;
  bool _saving = false;

  bool get _isEditing => widget.farm != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farm?.name ?? '');
    _typeController = TextEditingController(text: widget.farm?.type ?? '');
    _sizeController = TextEditingController(
      text: widget.farm?.size != null ? widget.farm!.size.toString() : '',
    );
    _location = widget.farm?.location ?? const GeoPoint(0, 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GpsLocationPicker(
          initialLocation: _location,
          title: 'Farm Location',
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

  Future<void> _saveFarm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_location == null ||
        (_location!.latitude == 0 && _location!.longitude == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please set a location for the farm'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final farm = Farm(
        id: widget.farm?.id ?? '', // Will be set by database if creating
        name: _nameController.text.trim(),
        location: _location!,
        type: _typeController.text.trim(),
        size: int.parse(_sizeController.text.trim()),
        camps: widget.farm?.camps ?? [],
        cattle: widget.farm?.cattle ?? [],
      );

      // Save farm to Supabase
      if (_isEditing) {
        await FarmDbService().updateFarm(farm);
      } else {
        await FarmDbService().createFarm(widget.farmerId, farm);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Farm updated successfully!'
                  : 'Farm created successfully!',
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
            content: Text('Error saving farm: $e'),
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
          _isEditing ? 'Edit Farm' : 'Add New Farm',
          style: TextColorTheme.heading,
        ),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _saveFarm,
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
                          Icons.agriculture,
                          size: 60,
                          color: darkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Farm Name
                    Text(
                      'Farm Name *',
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
                          return 'Please enter a farm name';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., Green Valley Farm',
                        prefixIcon: const Icon(Icons.agriculture),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Farm Type
                    Text(
                      'Farm Type *',
                      style: TextColorTheme.heading.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _typeController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a farm type';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., Cattle Ranch, Dairy, Mixed',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Farm Size
                    Text(
                      'Farm Size (hectares) *',
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
                          return 'Please enter the farm size';
                        }
                        final size = int.tryParse(value);
                        if (size == null || size <= 0) {
                          return 'Please enter a valid size';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., 500',
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
                      label: 'Farm Location',
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveFarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: baige,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Farm' : 'Create Farm',
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
