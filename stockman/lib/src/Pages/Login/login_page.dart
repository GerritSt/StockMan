import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/text_theme.dart';
import '../../config/app_theme.dart';
import 'dart:async';
import 'package:stockman/src/providers/farmer_db_service.dart';
import 'package:stockman/src/models/farmer_profile.dart';
import 'package:stockman/src/config/constants.dart';
import 'package:stockman/src/config/supabase_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // This is a timer that only check the email controller every 500 milliseconds once there has not been typed
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final email = _emailController.text.trim();
      print(email);
      // Call your database/email check function here
      // Example: bool exists = await checkIfEmailExists(email);
      // Then update your UI or state accordingly
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      var email = _emailController.text;
      print(email);
      final authResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update last sign-in timestamp
      if (authResponse.user != null) {
        await FarmerDbService().updateLastSignin(authResponse.user!.id);
      }

      // On success, navigation will be handled by the main app
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during login';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      dlog('Google sign-in started');

      // Initialize GoogleSignIn with the web client ID for getting ID token
      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleWebClientId,
        scopes: ['email', 'profile'],
      );

      // Sign out first to ensure clean sign-in flow
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        dlog('Google sign-in cancelled by user');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google sign-in cancelled.';
        });
        return;
      }

      dlog('Google user signed in: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      dlog('ID Token: ${idToken != null ? "present" : "null"}');
      dlog('Access Token: ${accessToken != null ? "present" : "null"}');

      if (idToken == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to get authentication token. Please try again.';
        });
        return;
      }

      dlog('Signing in to Supabase with Google credentials');
      final authResponse =
          await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      dlog('Supabase sign-in successful: ${authResponse.user?.email}');

      // Check if farmer record exists, create if not
      if (authResponse.user != null) {
        final farmerExists = await _checkFarmerExists(authResponse.user!.id);
        if (!farmerExists) {
          dlog('Creating farmer record for new Google user');

          // Split the display name into name and surname
          final nameParts = _splitName(googleUser.displayName);

          final farmer = Farmer(
            id: authResponse.user!.id,
            name: nameParts['name']!,
            surname: nameParts['surname']!,
            email: googleUser.email,
            phone: '',
            location: NOWHERE,
            farms: [],
          );
          await FarmerDbService().addFarmer(farmer);
          dlog(
              'Farmer record created for Google user: ${authResponse.user!.id}');
        } else {
          dlog(
              'Farmer record already exists for user: ${authResponse.user!.id}');
        }

        // Update last sign-in timestamp
        await FarmerDbService().updateLastSignin(authResponse.user!.id);
      }

      dlog('Google sign-in completed successfully');
      // Success! Navigation will be handled by the main app
    } on AuthException catch (e) {
      dlog('AuthException during Google sign-in: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      dlog('Error during Google sign-in: ${e.toString()}');
      setState(() {
        _errorMessage = 'Google sign-in failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to check if farmer exists
  Future<bool> _checkFarmerExists(String authId) async {
    try {
      final farmer = await FarmerDbService().getFarmer(authId);
      return farmer.id.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Helper method to check which auth provider(s) an email is registered with
  Future<String?> _checkEmailProvider(String email) async {
    try {
      // Check if email exists in farmers table
      final response = await Supabase.instance.client
          .from('farmers')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();

      if (response == null) {
        return null; // Email not registered
      }

      // Get the user's auth providers
      final userId = response['id'];
      final userResponse = await Supabase.instance.client.auth.admin
          .getUserById(userId)
          .catchError((_) => null);

      // Since we can't access admin API from client, we'll use a simpler approach:
      // Try to check if they have a password set by looking at metadata
      // For now, we'll assume Google if the email exists
      return 'google'; // Simplified - assumes Google OAuth
    } catch (e) {
      dlog('Error checking email provider: $e');
      return null;
    }
  }

  // Helper method to split full name into first and last name
  Map<String, String> _splitName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return {'name': 'User', 'surname': ''};
    }

    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return {'name': parts[0], 'surname': ''};
    } else if (parts.length == 2) {
      return {'name': parts[0], 'surname': parts[1]};
    } else {
      // If more than 2 parts, first name is first word, surname is rest
      return {'name': parts[0], 'surname': parts.sublist(1).join(' ')};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: baige,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/images/stockman_logo_test_1.png',
                    height: 120),
                const SizedBox(height: 24),
                // Heading
                Text('Welcome to StockMan', style: TextColorTheme.heading),
                const SizedBox(height: 8),
                Text('Sign in to continue', style: TextColorTheme.inAppText),
                const SizedBox(height: 24),
                // Card containing the sign-in elements
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Text Email
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        // Text Password
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        // Text: display errorMessage if there is one
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        // Button: Login
                        // onPressed => _login
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkGreen,
                              foregroundColor: baige,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Button: Don't have an account? Register
                        // onPressed => navigator.push route to RegisterPage
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                          child: const Text('Don\'t have an account? Register'),
                        ),
                        const SizedBox(height: 8),
                        // Text: or
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('or'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Button: Sign in with Google
                        // onPressed => _loginWithGoogle
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.g_mobiledata,
                                size: 28, color: darkGreen),
                            label: const Text('Sign in with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: darkGreen,
                              side: const BorderSide(color: darkGreen),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isLoading ? null : _loginWithGoogle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
