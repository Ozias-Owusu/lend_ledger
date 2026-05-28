import 'package:flutter/material.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/pages/reset_password_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final appState = context.read<AppState>();
    try {
      await appState.forgotPassword(_emailCtl.text);
      if (!mounted) return;
      setState(() => _loading = false);
      SnackbarUtils.showSuccess(
        context,
        'If that email exists, reset instructions were sent.',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(email: _emailCtl.text.trim()),
        ),
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
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your account email. We will send you a reset token.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailCtl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _submit,
                      child: const Text('Send reset link'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
