import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stockman/src/config/app_theme.dart';
import 'package:stockman/src/config/text_theme.dart';
import 'package:stockman/src/providers/farmer_db_service.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/utils/validation.dart';
import 'package:stockman/src/providers/profile_image_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final Farmer farmer;
  const EditProfilePage({super.key, required this.farmer});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  File? _selectedImage;
  bool _uploadingImage = false;
  final ProfileImageService _imageService = ProfileImageService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farmer.name);
    _surnameController = TextEditingController(text: widget.farmer.surname);
    _emailController = TextEditingController(text: widget.farmer.email);
    _phoneController = TextEditingController(text: widget.farmer.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      print('DEBUG: Starting image pick with source: $source');
      final image = await _imageService.pickImage(source: source);
      print('DEBUG: Image picker returned: ${image?.path ?? "null"}');

      if (image == null) {
        print('DEBUG: Image is null - user cancelled or error occurred');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      print('DEBUG: Image selected successfully: ${image.path}');

      setState(() {
        _selectedImage = image;
        _uploadingImage = true;
      });

      // Upload image
      final imageUrl = await _imageService.uploadProfileImage(
        widget.farmer.id,
        image,
      );

      if (imageUrl != null) {
        // Delete old image if exists
        if (widget.farmer.profileImageUrl != null) {
          await _imageService
              .deleteProfileImage(widget.farmer.profileImageUrl!);
        }

        // Update database
        await _imageService.updateProfileImageUrl(widget.farmer.id, imageUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile image updated!'),
              backgroundColor: darkGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Failed to upload image. Check if storage bucket exists.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      setState(() => _uploadingImage = false);
    } catch (e) {
      setState(() => _uploadingImage = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Profile Photo',
                style: TextColorTheme.heading.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.photo_library, color: darkGreen),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  print('DEBUG: Gallery option tapped');
                  Navigator.pop(context);
                  print(
                      'DEBUG: Calling _pickAndUploadImage with gallery source');
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: darkGreen),
                title: const Text('Take a Photo'),
                onTap: () {
                  print('DEBUG: Camera option tapped');
                  Navigator.pop(context);
                  print(
                      'DEBUG: Calling _pickAndUploadImage with camera source');
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              if (widget.farmer.profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() => _uploadingImage = true);
                    await _imageService
                        .deleteProfileImage(widget.farmer.profileImageUrl!);
                    await _imageService.updateProfileImageUrl(
                        widget.farmer.id, null);
                    setState(() {
                      _selectedImage = null;
                      _uploadingImage = false;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Profile photo removed'),
                          backgroundColor: darkGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedFarmer = Farmer(
        id: widget.farmer.id,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: const GeoPoint(0, 0), // Location no longer stored in database
        farms: widget.farmer.farms,
        profileImageUrl: widget.farmer.profileImageUrl, // Preserve image URL
      );
      await FarmerDbService().addFarmer(updatedFarmer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: darkGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baige,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: baige,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Photo Section
              GestureDetector(
                onTap: _uploadingImage ? null : _showImageSourceDialog,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: darkGreen,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: darkGreen.withOpacity(0.1),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (widget.farmer.profileImageUrl != null
                                ? NetworkImage(widget.farmer.profileImageUrl!)
                                : null) as ImageProvider?,
                        child: (widget.farmer.profileImageUrl == null &&
                                _selectedImage == null)
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: darkGreen,
                              )
                            : null,
                      ),
                      if (_uploadingImage)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: baige,
                            ),
                          ),
                        ),
                      if (!_uploadingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: darkGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: baige,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to change photo',
                style: TextColorTheme.inAppText.copyWith(
                  fontSize: 14,
                  color: darkGreen.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              // Form Fields
              _buildFormField(
                controller: _nameController,
                label: 'First Name',
                icon: Icons.person,
                validator: validateName,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: _surnameController,
                label: 'Surname',
                icon: Icons.person_outline,
                validator: validateName,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                readOnly: true,
                helperText: 'Email cannot be changed',
              ),
              const SizedBox(height: 16),
              _buildFormField(
                controller: _phoneController,
                label: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: validatePhone,
              ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: baige,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        style: TextColorTheme.inAppText.copyWith(
          fontSize: 16,
          color: readOnly ? darkGreen.withOpacity(0.6) : darkGreen,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: darkGreen.withOpacity(0.7),
            fontSize: 16,
          ),
          helperText: helperText,
          helperStyle: TextStyle(
            color: darkGreen.withOpacity(0.5),
            fontSize: 12,
          ),
          prefixIcon: Icon(
            icon,
            color: readOnly ? darkGreen.withOpacity(0.5) : darkGreen,
            size: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
