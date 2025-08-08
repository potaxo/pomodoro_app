// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pomodoro_record.dart';

enum TimerMode { stopwatch, countdown }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  int _totalSeconds = 0;
  int _initialCountdownSeconds = 0;
  bool _isRunning = false;
  TimerMode _timerMode = TimerMode.stopwatch;

  int _crushedTomatoes = 0;
  int _halfTomatoes = 0;
  int _wholeTomatoes = 0;

  @override
  void initState() {
    super.initState();
    _loadUnsavedCounts(); // Load counts that haven't been saved to history yet
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  // --- Data Persistence Logic ---
  // Loads the current session's counts (not the history)
  Future<void> _loadUnsavedCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _crushedTomatoes = prefs.getInt('unsaved_crushed') ?? 0;
      _halfTomatoes = prefs.getInt('unsaved_half') ?? 0;
      _wholeTomatoes = prefs.getInt('unsaved_whole') ?? 0;
    });
  }

  // Saves the current session's counts temporarily
  Future<void> _saveUnsavedCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unsaved_crushed', _crushedTomatoes);
    await prefs.setInt('unsaved_half', _halfTomatoes);
    await prefs.setInt('unsaved_whole', _wholeTomatoes);
  }
  
  // Saves the completed session to our Hive database history
  Future<void> _saveSessionToHistory() async {
    // Don't save if all counts are zero
    if (_crushedTomatoes == 0 && _halfTomatoes == 0 && _wholeTomatoes == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some tomatoes before saving!')),
      );
      return;
    }
    
    final box = Hive.box<PomodoroRecord>('pomodoro_box');
    final newRecord = PomodoroRecord()
      ..date = DateTime.now()
      ..crushedTomatoes = _crushedTomatoes
      ..halfTomatoes = _halfTomatoes
      ..wholeTomatoes = _wholeTomatoes;

    await box.add(newRecord);

    // Reset the counters for the next session
    setState(() {
      _crushedTomatoes = 0;
      _halfTomatoes = 0;
      _wholeTomatoes = 0;
    });
    
    // Clear the unsaved counts as well
    await _saveUnsavedCounts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session saved to history!')),
    );
  }

  // --- Timer Logic ---
  void _startTimer() {
    setState(() { _isRunning = true; });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerMode == TimerMode.stopwatch) {
          _totalSeconds++;
        } else {
          if (_totalSeconds > 0) {
            _totalSeconds--;
          } else { _stopTimer(); }
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() { _isRunning = false; });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _totalSeconds = _timerMode == TimerMode.countdown ? _initialCountdownSeconds : 0;
      _isRunning = false;
    });
  }
  
  void _setTimerDuration(int minutes) {
    _timer?.cancel();
    setState(() {
      _timerMode = TimerMode.countdown;
      _initialCountdownSeconds = minutes * 60;
      _totalSeconds = _initialCountdownSeconds;
      _isRunning = false;
    });
  }

  // --- Tomato Counter Logic ---
  void _updateTomatoCount(String type, int amount) {
    setState(() {
      switch (type) {
        case 'crushed':
          _crushedTomatoes = (_crushedTomatoes + amount).clamp(0, 99);
          break;
        case 'half':
          _halfTomatoes = (_halfTomatoes + amount).clamp(0, 99);
          break;
        case 'whole':
          _wholeTomatoes = (_wholeTomatoes + amount).clamp(0, 99);
          break;
      }
    });
    _saveUnsavedCounts(); // Save current progress automatically
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Focus'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                _formatTime(_totalSeconds),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 20),
              ToggleButtons(
                isSelected: [_timerMode == TimerMode.stopwatch, _timerMode == TimerMode.countdown],
                onPressed: (index) {
                  setState(() {
                    _timerMode = index == 0 ? TimerMode.stopwatch : TimerMode.countdown;
                    _resetTimer();
                  });
                },
                borderRadius: BorderRadius.circular(8.0),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Stopwatch')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Countdown')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(_isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    iconSize: 50,
                    onPressed: _isRunning ? _stopTimer : _startTimer,
                    color: Theme.of(context).primaryColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_circle_filled),
                    iconSize: 50,
                    onPressed: _resetTimer,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  _buildTomatoCounter('Crushed Tomato', '5 min', _crushedTomatoes, 'crushed', 5),
                  const SizedBox(height: 16),
                  _buildTomatoCounter('Half Tomato', '12 min', _halfTomatoes, 'half', 12),
                  const SizedBox(height: 16),
                  _buildTomatoCounter('Whole Tomato', '25 min', _wholeTomatoes, 'whole', 25),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveSessionToHistory, // UPDATED
                    icon: const Icon(Icons.save),
                    label: const Text('Save Session'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () { /* Stats action later */ },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Statistics'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTomatoCounter(String name, String duration, int count, String type, int minutes) {
    return GestureDetector(
      onTap: () => _setTimerDuration(minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 30),
              onPressed: () => _updateTomatoCount(type, -1),
            ),
            Column(
              children: [
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                Text(duration, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 30),
              onPressed: () => _updateTomatoCount(type, 1),
            ),
          ],
        ),
      ),
    );
  }
}