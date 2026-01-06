import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stockman/src/config/constants.dart';

class ProfileImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      dlog('Starting image picker with source: $source');

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512, // Resize for performance
        maxHeight: 512,
        imageQuality: 85,
      );

      dlog('Image picker returned: ${image?.path ?? "null"}');

      if (image == null) {
        dlog('No image was selected by user');
        return null;
      }

      final file = File(image.path);
      dlog('Image file created: ${file.path}, exists: ${await file.exists()}');
      return file;
    } catch (e) {
      dlog('Error picking image: $e');
      dlog('Error stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Upload image to Supabase Storage
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$fileName';

      dlog('Uploading image to: $filePath');

      // Upload to Supabase Storage
      await _supabase.storage.from('profile-images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final String imageUrl =
          _supabase.storage.from('profile-images').getPublicUrl(filePath);

      dlog('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      dlog('Error uploading image: $e');
      return null;
    }
  }

  /// Delete old profile image
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the filename (last segment after 'profile-images')
      final bucketIndex = pathSegments.indexOf('profile-images');
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) return;

      final fileName = pathSegments.last;

      await _supabase.storage.from('profile-images').remove([fileName]);

      dlog('Old image deleted: $fileName');
    } catch (e) {
      dlog('Error deleting old image: $e');
    }
  }

  /// Update profile image URL in database
  Future<void> updateProfileImageUrl(String userId, String? imageUrl) async {
    try {
      await _supabase
          .from('farmers')
          .update({'profile_image_url': imageUrl}).eq('id', userId);

      dlog('Profile image URL updated in database');
    } catch (e) {
      dlog('Error updating profile image URL: $e');
      rethrow;
    }
  }
}
