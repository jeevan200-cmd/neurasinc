import 'package:flutter/material.dart';

class NeuralFunScreen extends StatelessWidget {
  const NeuralFunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Neural Fun',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Games & Activities',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  GameCard(
                    title: 'Brain Map',
                    color: Colors.orange,
                    icon: 'brain_icon.png',
                    onTap: () {
                      // TODO: Implement brain mapping game
                    },
                  ),
                  GameCard(
                    title: 'Focus Spinner',
                    color: Colors.blue,
                    icon: 'spinner_icon.png',
                    onTap: () {
                      // TODO: Implement focus spinner game
                    },
                  ),
                  GameCard(
                    title: 'Memory Match',
                    color: Colors.purple,
                    icon: 'memory_icon.png',
                    onTap: () {
                      // TODO: Implement memory matching game
                    },
                  ),
                  GameCard(
                    title: 'Calm Zone',
                    color: Colors.green,
                    icon: 'calm_icon.png',
                    onTap: () {
                      // TODO: Implement calm zone activity
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final String title;
  final Color color;
  final String icon;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _getIconData(),
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (title) {
      case 'Brain Map':
        return Icons.psychology;
      case 'Focus Spinner':
        return Icons.refresh;
      case 'Memory Match':
        return Icons.grid_view;
      case 'Calm Zone':
        return Icons.spa;
      default:
        return Icons.games;
    }
  }
}
