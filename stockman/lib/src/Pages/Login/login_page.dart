import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/text_theme.dart';
import '../../config/app_theme.dart';
import 'dart:async';

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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // On success, navigation will be handled by the main app
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _promptForPassword(String email) async {
    String? password;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController _passwordDialogController =
            TextEditingController();
        return AlertDialog(
          backgroundColor: baige,
          title: Text('Enter Password', style: TextColorTheme.heading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'To link your Google account, please enter the password for $email.',
                  style: TextColorTheme.inAppText),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordDialogController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password', prefixIcon: Icon(Icons.lock)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen, foregroundColor: baige),
              onPressed: () {
                password = _passwordDialogController.text;
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return password;
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      print('Google sign-in started');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print('Google user is null');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google sign-in cancelled.';
        });
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // User is already signed in (email/password), try to link Google
        try {
          await currentUser.linkWithCredential(googleCredential);
          // Success! Now user can use both methods
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            // Google already linked, just sign in with Google
            await FirebaseAuth.instance.signInWithCredential(googleCredential);
          } else if (e.code == 'credential-already-in-use') {
            setState(() {
              _errorMessage =
                  'This Google account is already linked to another user.';
            });
          } else {
            setState(() {
              _errorMessage = e.message;
            });
          }
        }
      } else {
        // No user signed in, proceed as normal
        try {
          await FirebaseAuth.instance.signInWithCredential(googleCredential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            // Handle account linking as before
            final email = e.email;
            final pendingCredential = e.credential;
            if (pendingCredential == null) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'No pending credential to link. Please contact support.';
              });
              return;
            }
            final password = await _promptForPassword(email!);
            if (password == null || password.isEmpty) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Password required to link accounts.';
              });
              return;
            }
            try {
              await FirebaseAuth.instance.signOut();
              final userCredential =
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              await userCredential.user!.linkWithCredential(pendingCredential);
            } on FirebaseAuthException catch (linkError) {
              setState(() {
                _isLoading = false;
                _errorMessage = linkError.message ?? 'Failed to link accounts.';
              });
              return;
            }
          } else {
            setState(() {
              _errorMessage = e.message;
            });
          }
        }
      }
    } catch (e) {
      print('Other error: ${e.toString()}');
      setState(() {
        _errorMessage = 'Google sign-in failed.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
