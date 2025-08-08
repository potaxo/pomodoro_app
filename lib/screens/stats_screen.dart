// lib/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pomodoro_record.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the Hive box that we opened in main.dart
    final Box<PomodoroRecord> box = Hive.box<PomodoroRecord>('pomodoro_box');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Productivity Stats'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // ValueListenableBuilder is a special widget that listens to our Hive box.
      // Whenever the data in the box changes, this builder will automatically
      // rerun and update the UI with the latest data!
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<PomodoroRecord> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text(
                'No saved sessions yet.\nComplete a session and save it!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // --- Data Processing Logic ---
          // Here, we calculate the total for each tomato type
          int totalCrushed = 0;
          int totalHalf = 0;
          int totalWhole = 0;

          for (var record in box.values) {
            totalCrushed += record.crushedTomatoes;
            totalHalf += record.halfTomatoes;
            totalWhole += record.wholeTomatoes;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Total Tomatoes Completed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // This Expanded widget makes the chart take up all available space
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (totalCrushed + totalHalf + totalWhole) * 1.2, // Set a dynamic max Y
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              String text = '';
                              switch (value.toInt()) {
                                case 0:
                                  text = 'Crushed';
                                  break;
                                case 1:
                                  text = 'Half';
                                  break;
                                case 2:
                                  text = 'Whole';
                                  break;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(text),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        // Bar for Crushed Tomatoes
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(toY: totalCrushed.toDouble(), color: Colors.red[200], width: 25, borderRadius: BorderRadius.circular(4)),
                        ]),
                        // Bar for Half Tomatoes
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(toY: totalHalf.toDouble(), color: Colors.red[400], width: 25, borderRadius: BorderRadius.circular(4)),
                        ]),
                        // Bar for Whole Tomatoes
                        BarChartGroupData(x: 2, barRods: [
                          BarChartRodData(toY: totalWhole.toDouble(), color: Colors.red[700], width: 25, borderRadius: BorderRadius.circular(4)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}