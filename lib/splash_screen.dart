import 'package:flutter/material.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl, _textCtrl, _loadingCtrl;
  late Animation<double> _logoScale, _logoOpacity, _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadingCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  void _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      Navigator.pushReplacement(context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ));
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose(); _textCtrl.dispose(); _loadingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF0F2040)]),
        ),
        child: Stack(children: [
          // Grid background
          CustomPaint(painter: _GridPainter(), size: MediaQuery.of(context).size),
          // Glow
          Center(child: Container(width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFF00C2FF).withOpacity(0.12), Colors.transparent])))),
          // Content
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedBuilder(
                animation: _logoCtrl,
                builder: (_, child) => Opacity(opacity: _logoOpacity.value,
                    child: Transform.scale(scale: _logoScale.value, child: child)),
                child: _buildLogo(),
              ),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _textCtrl,
                builder: (_, child) => Opacity(opacity: _textOpacity.value,
                    child: SlideTransition(position: _textSlide, child: child)),
                child: Column(children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF00C2FF), Color(0xFF0070FF)]).createShader(b),
                    child: const Text('PATROL', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 8)),
                  ),
                  const Text('SECURE', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 48, fontWeight: FontWeight.w300, color: Color(0xFF8BA3C0), letterSpacing: 8)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF00C2FF).withOpacity(0.3)), borderRadius: BorderRadius.circular(20)),
                    child: const Text('CAMPUS DISCIPLINE MANAGEMENT', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 11, letterSpacing: 3, color: Color(0xFF4A6080), fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
          // Bottom loading bar
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _textCtrl,
              builder: (_, child) => Opacity(opacity: _textOpacity.value, child: child),
              child: Column(children: [
                AnimatedBuilder(
                  animation: _loadingCtrl,
                  builder: (_, __) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 80),
                    height: 2,
                    decoration: BoxDecoration(color: const Color(0xFF1E3555), borderRadius: BorderRadius.circular(1)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _loadingCtrl.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF0070FF)]),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [BoxShadow(color: const Color(0xFF00C2FF).withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Initializing secure connection...', style: TextStyle(color: Color(0xFF4A6080), fontFamily: 'Rajdhani', fontSize: 12, letterSpacing: 1.5)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [Color(0xFF00C2FF), Color(0xFF0070FF)]),
        boxShadow: [BoxShadow(color: const Color(0xFF00C2FF).withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
      ),
      child: Stack(alignment: Alignment.center, children: [
        Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0A1628).withOpacity(0.4))),
        const Icon(Icons.shield_rounded, size: 52, color: Colors.white),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E3555).withOpacity(0.4)..strokeWidth = 0.3;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
