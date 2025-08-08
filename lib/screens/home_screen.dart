import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Focus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // mainAxisAlignment centers the children vertically
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // crossAxisAlignment stretches the children to fill the horizontal space
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Timer Display (Placeholder)
            const Text(
              '00:00:00',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),

            // 2. Tomato Counters Section
            Column(
              children: [
                _buildTomatoCounter('Crushed Tomato', '5 min'),
                const SizedBox(height: 16), // Adds space between counters
                _buildTomatoCounter('Half Tomato', '12 min'),
                const SizedBox(height: 16),
                _buildTomatoCounter('Whole Tomato', '25 min'),
              ],
            ),

            // 3. Bottom Buttons Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Save Button (Placeholder)
                ElevatedButton.icon(
                  onPressed: () {
                    // Action will be added later
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                // Statistics Button (Placeholder)
                ElevatedButton.icon(
                  onPressed: () {
                    // Action will be added later
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Statistics'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // A helper method to build the tomato counter rows to avoid repeating code
  Widget _buildTomatoCounter(String name, String duration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.remove_circle_outline, size: 30),
        Column(
          children: [
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            Text(duration, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Icon(Icons.add_circle_outline, size: 30),
      ],
    );
  }
}