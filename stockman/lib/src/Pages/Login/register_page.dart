import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stockman/src/providers/farmer_db_service.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/config/constants.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    // Check if email already exists
    final emailExists = await _checkEmailExists(_emailController.text.trim());
    if (emailExists) {
      setState(() {
        _errorMessage =
            'This email is already registered. Please sign in using the method you originally registered with (Email/Password or Google Sign-In).';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create farmer record in database
      if (response.user != null) {
        final farmer = Farmer(
          id: response.user!.id,
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'New User',
          surname: '',
          email: _emailController.text.trim(),
          phone: '',
          location: NOWHERE,
          farms: [],
        );

        await FarmerDbService().addFarmer(farmer);
        dlog('Farmer record created for user: ${response.user!.id}');
      }

      // Check if email confirmation is required
      if (response.session == null) {
        // Email confirmation required - show message and go back to login
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Check Your Email'),
              content: const Text(
                'We\'ve sent you a confirmation email. Please check your inbox and click the confirmation link to activate your account.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to login
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
      // If session exists, navigation will be handled by the main app's StreamBuilder
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during registration';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to check if email already exists
  Future<bool> _checkEmailExists(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('farmers')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();
      return response != null;
    } catch (e) {
      dlog('Error checking email: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name (Optional)',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
