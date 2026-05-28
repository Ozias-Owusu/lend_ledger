import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/network/api_exception.dart';
import '../services/auth_api_service.dart';
import '../state/app_state.dart';
import '../utils/snackbar_utils.dart';
import 'app_shell_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();
  final _nameCtl = TextEditingController();

  bool _loading = false;
  bool _isLogin = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _canUseBiometrics = false;
  String _selectedRole = AuthApiService.availableRoles.first;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus(); // <-- Check status when page loads
  }

  Future<void> _checkBiometricStatus() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final canUse = await appState.areBiometricsEnabled();
    if (mounted) {
      setState(() {
        _canUseBiometrics = canUse;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _loading = true);
    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.biometricLogin();

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const AppShellPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login failed or was canceled.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleFormType() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailCtl.clear();
      _passCtl.clear();
      _confirmPassCtl.clear();
      _nameCtl.clear();
      _selectedRole = AuthApiService.availableRoles.first;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      if (_isLogin) {
        final success = await appState.login(
          _emailCtl.text.trim(),
          _passCtl.text,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const AppShellPage()),
          );
        } else {
          SnackbarUtils.showError(context, 'Invalid login credentials.');
        }
      } else {
        final success = await appState.signUp(
          name: _nameCtl.text.trim(),
          email: _emailCtl.text.trim(),
          password: _passCtl.text,
          confirmPassword: _confirmPassCtl.text,
          role: _selectedRole,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const AppShellPage()),
          );
        } else {
          SnackbarUtils.showError(context, 'Sign up failed.');
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackbarUtils.showError(context, e);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackbarUtils.showError(context, e);
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
                            radius:
                                50, // Reduced size to fit nicely in the card
                            backgroundImage: AssetImage(
                              'assets/images/auth.jpg',
                            ),
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
                            isPassword: true,
                            label: 'Password',
                            icon: Icons.lock,
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
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            _buildTextFormField(
                              controller: _confirmPassCtl,
                              isPassword: true,
                              isConfirmPassword: true,
                              label: 'Confirm Password',
                              icon: Icons.lock_outline,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (v != _passCtl.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                labelStyle: TextStyle(color: Colors.grey.shade700),
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                              ),
                              items: AuthApiService.availableRoles
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedRole = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a role';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (_isLogin) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ForgotPasswordPage(
                                              initialEmail: _emailCtl.text.trim(),
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

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
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                    ),
                                    onPressed: _submit,
                                    child: Text(
                                      _isLogin ? 'Login' : 'Sign Up',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 6),
                          // --- Biometric Login Button ---
                          if (_isLogin && _canUseBiometrics)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Login with Biometrics'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  foregroundColor: Colors.indigo,
                                  side: const BorderSide(color: Colors.indigo),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                onPressed: _handleBiometricLogin,
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

  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final obscure = isPassword
        ? (isConfirmPassword ? !_showConfirmPassword : !_showPassword)
        : false;

    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon: Icon(icon, color: Colors.grey.shade600),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirmPassword) {
                      _showConfirmPassword = !_showConfirmPassword;
                    } else {
                      _showPassword = !_showPassword;
                    }
                  });
                },
              )
            : null,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
