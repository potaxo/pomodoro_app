// lib/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pomodoro_record.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<PomodoroRecord> box = Hive.box<PomodoroRecord>('pomodoro_box');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Productivity Stats'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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
          int totalCrushed = 0;
          int totalHalf = 0;
          int totalWhole = 0;

          for (var record in box.values) {
            totalCrushed += record.crushedTomatoes;
            totalHalf += record.halfTomatoes;
            totalWhole += record.wholeTomatoes;
          }

          final maxVal = [totalCrushed, totalHalf, totalWhole]
              .reduce((curr, next) => curr > next ? curr : next)
              .toDouble();

          // THE FIX IS HERE!
          // We wrap the entire page content in a SingleChildScrollView.
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Total Tomatoes Completed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  
                  // We can still use a SizedBox to suggest a good default height for the chart.
                  SizedBox(
                    height: 350, 
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxVal * 1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40, // Increased space for the titles
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
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(text, style: const TextStyle(fontSize: 14)),
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
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(toY: totalCrushed.toDouble(), color: Colors.red[200], width: 35, borderRadius: BorderRadius.circular(4)),
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(toY: totalHalf.toDouble(), color: Colors.red[400], width: 35, borderRadius: BorderRadius.circular(4)),
                          ]),
                          BarChartGroupData(x: 2, barRods: [
                            BarChartRodData(toY: totalWhole.toDouble(), color: Colors.red[700], width: 35, borderRadius: BorderRadius.circular(4)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}