import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the package

// An enum to represent the two timer modes
enum TimerMode { stopwatch, countdown }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables for the timer
  Timer? _timer;
  int _totalSeconds = 0;
  int _initialCountdownSeconds = 0;
  bool _isRunning = false;
  TimerMode _timerMode = TimerMode.stopwatch; // Default mode is stopwatch

  // State variables for tomato counts
  int _crushedTomatoes = 0;
  int _halfTomatoes = 0;
  int _wholeTomatoes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  // --- Data Persistence Logic ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _crushedTomatoes = prefs.getInt('crushedTomatoes') ?? 0;
      _halfTomatoes = prefs.getInt('halfTomatoes') ?? 0;
      _wholeTomatoes = prefs.getInt('wholeTomatoes') ?? 0;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('crushedTomatoes', _crushedTomatoes);
    await prefs.setInt('halfTomatoes', _halfTomatoes);
    await prefs.setInt('wholeTomatoes', _wholeTomatoes);
    
    // THE FIX IS HERE!
    // We check if the widget is still on the screen before using its context.
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress Saved!')),
    );
  }


  // --- Timer Logic ---
  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerMode == TimerMode.stopwatch) {
          _totalSeconds++;
        } else {
          if (_totalSeconds > 0) {
            _totalSeconds--;
          } else {
            _stopTimer();
          }
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
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
  }

  // Helper to format the time string
  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Build Method ---
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
                    onPressed: _saveData,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
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