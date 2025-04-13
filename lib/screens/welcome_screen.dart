import 'package:flutter/material.dart';
import 'permissions_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const BrainLogo(),
              const SizedBox(height: 40),
              Text(
                'Stay Calm, Stay Healthy',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Neurasync',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const PermissionsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class BrainLogo extends StatelessWidget {
  const BrainLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: CustomPaint(
        painter: BrainPainter(),
      ),
    );
  }
}

class BrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint leftPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final Paint rightPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Left half of the brain
    final Path leftPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.5,
        size.width * 0.3,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.9,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.15,
        size.width * 0.3,
        size.height * 0.2,
      );

    // Right half of the brain (mirrored)
    final Path rightPath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.5,
        size.width * 0.7,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.9,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..lineTo(size.width * 0.5, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.15,
        size.width * 0.7,
        size.height * 0.2,
      );

    canvas.drawPath(leftPath, leftPaint);
    canvas.drawPath(rightPath, rightPaint);

    // Add some neural connections
    final Paint connectionPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.3 + i * 0.1);
      final path = Path()
        ..moveTo(size.width * 0.4, y)
        ..quadraticBezierTo(
          size.width * 0.5,
          y + size.height * 0.1,
          size.width * 0.6,
          y,
        );
      canvas.drawPath(path, connectionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
