import 'package:flutter/material.dart';
import 'package:lend_ledger/core/auth/password_policy.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/widgets/auth/password_form_field.dart';
import 'package:lend_ledger/pages/login_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.email = ''});

  final String email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtl;
  final _tokenCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _emailCtl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _tokenCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!PasswordPolicy.isValid(_passwordCtl.text)) {
      SnackbarUtils.showError(context, PasswordPolicy.requirementsSummary);
      return;
    }
    setState(() => _loading = true);

    final appState = context.read<AppState>();
    try {
      await appState.resetPassword(
        email: _emailCtl.text,
        token: _tokenCtl.text,
        newPassword: _passwordCtl.text,
        confirmPassword: _confirmCtl.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      SnackbarUtils.showSuccess(context, 'Password updated. Please sign in.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
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
      appBar: AppBar(title: const Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenCtl,
                decoration: const InputDecoration(
                  labelText: 'Reset token',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Token is required' : null,
              ),
              const SizedBox(height: 16),
              PasswordFormField(
                controller: _passwordCtl,
                label: 'New password',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtl,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (v != _passwordCtl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _submit,
                      child: const Text('Reset password'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
