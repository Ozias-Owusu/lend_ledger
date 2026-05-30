import 'package:flutter/material.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/pages/app_shell_page.dart';
import 'package:lend_ledger/pages/login_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    super.key,
    this.userId,
    this.token,
    this.preferGet = false,
  });

  final String? userId;
  final String? token;

  /// When true, uses GET /api/Auth/verify-email (email link style).
  final bool preferGet;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userIdCtl;
  late final TextEditingController _tokenCtl;
  bool _loading = false;
  bool _autoAttempted = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _userIdCtl = TextEditingController(text: widget.userId ?? '');
    _tokenCtl = TextEditingController(text: widget.token ?? '');

    final hasCredentials =
        (widget.userId?.isNotEmpty ?? false) &&
        (widget.token?.isNotEmpty ?? false);
    if (hasCredentials) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify(auto: true));
    }
  }

  @override
  void dispose() {
    _userIdCtl.dispose();
    _tokenCtl.dispose();
    super.dispose();
  }

  Future<void> _verify({bool auto = false}) async {
    if (auto) {
      if (_autoAttempted) return;
      _autoAttempted = true;
    } else if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = auto ? 'Verifying your email…' : null;
    });

    final appState = context.read<AppState>();
    try {
      await appState.verifyEmail(
        userId: _userIdCtl.text.trim(),
        token: _tokenCtl.text.trim(),
        preferGet: widget.preferGet || auto,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      SnackbarUtils.showSuccess(context, 'Email verified. Welcome!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShellPage()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = null;
      });
      if (!auto) {
        SnackbarUtils.showError(context, e);
      } else {
        SnackbarUtils.showError(
          context,
          '${e.message} You can try again below.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = null;
      });
      SnackbarUtils.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromLink =
        widget.userId != null &&
        widget.token != null &&
        widget.userId!.isNotEmpty &&
        widget.token!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_statusMessage != null) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
              ],
              if (!fromLink || !_loading) ...[
                Text(
                  fromLink
                      ? 'Confirming your email address.'
                      : 'Paste the user ID and token from your verification email.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _userIdCtl,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'User ID is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tokenCtl,
                  enabled: !_loading,
                  decoration: const InputDecoration(
                    labelText: 'Verification token',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Verification token is required'
                      : null,
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: () => _verify(),
                        child: const Text('Verify and sign in'),
                      ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                          (_) => false,
                        );
                      },
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
