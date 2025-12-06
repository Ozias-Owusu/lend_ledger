import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _nameCtl = TextEditingController();

  bool _loading = false;
  bool _isLogin = true;

  void _toggleFormType() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailCtl.clear();
      _passCtl.clear();
      _nameCtl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final appState = Provider.of<AppState>(context, listen: false);
    bool success;

    if (_isLogin) {
      success = await appState.login(_emailCtl.text.trim(), _passCtl.text);
    } else {
      success = await appState.signUp(
        name: _nameCtl.text.trim(),
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const DashboardPage()),
      );
    } else {
      final message = _isLogin ? 'Login failed' : 'Sign up failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900, // Set a base background color
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child:
            // *** FIX IS HERE: Wrap the Column in a Card ***
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Avatar ---
                      const CircleAvatar(
                        radius: 50, // Reduced size to fit nicely in the card
                        backgroundImage:
                        AssetImage('assets/images/auth.jpg'),
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(height: 16),

                      // --- Title ---
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Form Fields ---
                      if (!_isLogin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildTextFormField(
                            controller: _nameCtl,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                        ),
                      _buildTextFormField(
                        controller: _emailCtl,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(v)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _passCtl,
                        label: 'Password',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // --- Submit Button or Loader ---
                      _loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(
                            _isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Toggle Button ---
                      TextButton(
                        onPressed: _toggleFormType,
                        child: Text(
                          _isLogin
                              ? 'Don\'t have an account? Sign Up'
                              : 'Already have an account? Login',
                          style: TextStyle(color: Colors.indigo.shade700),
                        ),
                      )
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

  // Helper method styling is updated for a card-based UI
  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87), // Dark text for light card
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.grey.shade100, // Light background for fields
      ),
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
