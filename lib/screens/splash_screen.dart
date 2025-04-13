// @dart=2.17
import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Top neural branches
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: CustomPaint(
              painter: NeuralBranchesPainter(isTop: true),
            ),
          ),
          // Bottom neural branches
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: CustomPaint(
              painter: NeuralBranchesPainter(isTop: false),
            ),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _animation,
                  child: const Icon(
                    Icons.psychology,
                    size: 120,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _animation,
                  child: const Text(
                    'NeuraSync',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                RotationTransition(
                  turns: _animation,
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NeuralBranchesPainter extends CustomPainter {
  final bool isTop;

  NeuralBranchesPainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (isTop) {
      _drawTopBranches(canvas, size, paint);
    } else {
      _drawBottomBranches(canvas, size, paint);
    }
  }

  void _drawTopBranches(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Main branch
    path.moveTo(size.width * 0.7, 0);
    path.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.5,
      size.width * 0.3,
      size.height * 0.8,
    );

    // Sub branches
    _addBranch(path, size.width * 0.65, size.height * 0.2, -1);
    _addBranch(path, size.width * 0.6, size.height * 0.4, -0.8);
    _addBranch(path, size.width * 0.5, size.height * 0.6, -0.6);

    canvas.drawPath(path, paint);
  }

  void _drawBottomBranches(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // Main branch
    path.moveTo(size.width * 0.3, size.height);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5,
      size.width * 0.7,
      size.height * 0.2,
    );

    // Sub branches
    _addBranch(path, size.width * 0.35, size.height * 0.8, 1);
    _addBranch(path, size.width * 0.4, size.height * 0.6, 0.8);
    _addBranch(path, size.width * 0.5, size.height * 0.4, 0.6);

    canvas.drawPath(path, paint);
  }

  void _addBranch(Path path, double startX, double startY, double direction) {
    path.moveTo(startX, startY);
    path.quadraticBezierTo(
      startX + 40 * direction,
      startY,
      startX + 80 * direction,
      startY - 20,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
