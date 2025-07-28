import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        if (_isLogin) {
          // Login
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
        } else {
          // Registrierung
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          
          // Benutzer in Firestore anlegen
          await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'role': 'tester', // Standard-Rolle
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
          
          // Display Name setzen
          await credential.user!.updateDisplayName(_nameController.text.trim());
        }
        
        // Navigation erfolgt automatisch durch AuthStateChange
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'Kein Benutzer mit dieser E-Mail gefunden.';
              break;
            case 'wrong-password':
              _errorMessage = 'Falsches Passwort.';
              break;
            case 'email-already-in-use':
              _errorMessage = 'Diese E-Mail wird bereits verwendet.';
              break;
            case 'invalid-email':
              _errorMessage = 'Ungültige E-Mail-Adresse.';
              break;
            case 'weak-password':
              _errorMessage = 'Das Passwort ist zu schwach.';
              break;
            default:
              _errorMessage = 'Ein Fehler ist aufgetreten: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Ein unerwarteter Fehler ist aufgetreten.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icon
                      TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 2),
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.bug_report,
                                size: 50,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      // Titel
                      Text(
                        'Katta DB',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ÖPNV Fehler-Tracker',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Toggle Login/Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _isLogin ? null : () {
                              setState(() {
                                _isLogin = true;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              'Anmelden',
                              style: TextStyle(
                                color: _isLogin ? Colors.blue : Colors.grey,
                                fontSize: 16,
                                fontWeight: _isLogin ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Text(' | ', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: !_isLogin ? null : () {
                              setState(() {
                                _isLogin = false;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              'Registrieren',
                              style: TextStyle(
                                color: !_isLogin ? Colors.blue : Colors.grey,
                                fontSize: 16,
                                fontWeight: !_isLogin ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Name Field (nur bei Registrierung)
                      if (!_isLogin)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF1E1E1E),
                                ),
                                validator: (value) {
                                  if (!_isLogin && (value == null || value.isEmpty)) {
                                    return 'Bitte gib deinen Namen ein';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-Mail',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte E-Mail eingeben';
                          }
                          if (!value.contains('@')) {
                            return 'Bitte gültige E-Mail eingeben';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte Passwort eingeben';
                          }
                          if (!_isLogin && value.length < 6) {
                            return 'Passwort muss mindestens 6 Zeichen lang sein';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Anmelden' : 'Registrieren',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Passwort vergessen
                      if (_isLogin)
                        TextButton(
                          onPressed: () {
                            _showPasswordResetDialog();
                          },
                          child: const Text(
                            'Passwort vergessen?',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final resetEmailController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Passwort zurücksetzen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gib deine E-Mail-Adresse ein, um einen Link zum Zurücksetzen zu erhalten.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                decoration: InputDecoration(
                  labelText: 'E-Mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: resetEmailController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-Mail zum Zurücksetzen wurde gesendet!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fehler beim Senden der E-Mail'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Senden'),
            ),
          ],
        );
      },
    );
  }
}