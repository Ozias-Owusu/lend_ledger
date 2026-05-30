import 'package:flutter/material.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/widgets/auth/auth_animated_background.dart';

import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTheme.display(fontSize: 36);
    final bodyStyle = AppTheme.body(fontSize: 16, height: 1.5);

    return Scaffold(
      body: AuthAnimatedBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.9, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.softRose.withValues(alpha: 0.45),
                              AppTheme.mintGray.withValues(alpha: 0.35),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.softRose.withValues(alpha: 0.3),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 118,
                          backgroundImage:
                              AssetImage('assets/images/welcome.jpg'),
                          backgroundColor: Color(0xFFFFF6F2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Lend Ledger', style: titleStyle),
                    const SizedBox(height: 12),
                    Text(
                      'Track loans, repayments, and customers with ease.',
                      textAlign: TextAlign.center,
                      style: bodyStyle,
                    ),
                    const Spacer(flex: 3),
                    _LandingCta(onPressed: () => _openLogin(context)),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingCta extends StatefulWidget {
  const _LandingCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_LandingCta> createState() => _LandingCtaState();
}

class _LandingCtaState extends State<_LandingCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [AppTheme.softRose, Color(0xFFC4928C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.softRose.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(28),
                child: Center(
                  child: Text(
                    'Get started',
                    style: AppTheme.body(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
