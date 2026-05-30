import 'package:flutter/material.dart';
import 'package:lend_ledger/core/network/api_exception.dart';
import 'package:lend_ledger/pages/login_page.dart';
import 'package:lend_ledger/pages/verify_email_page.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';

class VerifyEmailPendingPage extends StatefulWidget {
  const VerifyEmailPendingPage({
    super.key,
    required this.email,
    this.registrationMessage,
  });

  final String email;
  final String? registrationMessage;

  @override
  State<VerifyEmailPendingPage> createState() => _VerifyEmailPendingPageState();
}

class _VerifyEmailPendingPageState extends State<VerifyEmailPendingPage> {
  bool _resending = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    final appState = context.read<AppState>();
    try {
      final message = await appState.resendVerificationEmail(widget.email);
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, message);
    } on ApiException catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.registrationMessage ??
        'We sent a verification link to your email. Open it on this device to activate your account.';

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mark_email_unread_outlined,
                        size: 72,
                        color: Colors.indigo.shade700,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verify your email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _resending ? null : _resend,
                          child: _resending
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Resend verification email'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VerifyEmailPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Enter verification details manually',
                          style: TextStyle(color: Colors.indigo.shade700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (_) => false,
                          );
                        },
                        child: Text(
                          'Back to sign in',
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
}
