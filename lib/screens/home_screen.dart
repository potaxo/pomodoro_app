// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomo/utils/perf.dart';
import '../models/pomodoro_record.dart';
import 'package:pomo/screens/stats_screen.dart';
import 'package:pomo/widgets/glass_container.dart';
import 'package:pomo/utils/always_on_top.dart';
import 'package:pomo/utils/platform.dart';

enum TimerMode { stopwatch, countdown }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  int _totalSeconds = 0; // backing value used for logic
  final ValueNotifier<int> _secondsVN = ValueNotifier<int>(0); // drives UI text only
  int _initialCountdownSeconds = 0;
  bool _isRunning = false;
  TimerMode _timerMode = TimerMode.stopwatch;

  int _crushedTomatoes = 0;
  int _halfTomatoes = 0;
  int _wholeTomatoes = 0;

  @override
  void initState() {
    super.initState();
    _loadUnsavedCounts();
  }

  @override
  void dispose() {
    _timer?.cancel();
  _secondsVN.dispose();
    super.dispose();
  }
  
  Future<void> _loadUnsavedCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _crushedTomatoes = prefs.getInt('unsaved_crushed') ?? 0;
      _halfTomatoes = prefs.getInt('unsaved_half') ?? 0;
      _wholeTomatoes = prefs.getInt('unsaved_whole') ?? 0;
    });
  }

  Future<void> _saveUnsavedCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unsaved_crushed', _crushedTomatoes);
    await prefs.setInt('unsaved_half', _halfTomatoes);
    await prefs.setInt('unsaved_whole', _wholeTomatoes);
  }
  
  Future<void> _saveSessionToHistory() async {
    if (_crushedTomatoes == 0 && _halfTomatoes == 0 && _wholeTomatoes == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some tomatoes before saving!'),
          duration: Duration(milliseconds: 500),
        ),
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

    setState(() {
      _crushedTomatoes = 0;
      _halfTomatoes = 0;
      _wholeTomatoes = 0;
    });
    
    await _saveUnsavedCounts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session saved to history!'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  void _startTimer() {
    setState(() { _isRunning = true; });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerMode == TimerMode.stopwatch) {
        _totalSeconds++;
        _secondsVN.value = _totalSeconds;
      } else {
        if (_totalSeconds > 0) {
          _totalSeconds--;
          _secondsVN.value = _totalSeconds;
        } else {
          _stopTimer();
        }
      }
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
  _secondsVN.value = _totalSeconds;
  }
  
  void _setTimerDuration(int minutes) {
    _timer?.cancel();
    setState(() {
      _timerMode = TimerMode.countdown;
      _initialCountdownSeconds = minutes * 60;
      _totalSeconds = _initialCountdownSeconds;
      _isRunning = false;
    });
  _secondsVN.value = _totalSeconds;
  }

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
    _saveUnsavedCounts();
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Expose for timer display widget (keeps logic in one place)
  String formatTimePublic(int s) => _formatTime(s);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Pomodoro Focus'),
          backgroundColor: Colors.transparent,
        actions: [
          if (PlatformEx.isWindows)
            FutureBuilder<bool>(
              future: AlwaysOnTop.get(),
              builder: (context, snap) {
                final pinned = snap.data == true;
                return IconButton(
                  tooltip: pinned ? 'Window Always on Top: ON' : 'Window Always on Top: OFF',
                  icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
                  onPressed: () async {
                    await AlwaysOnTop.toggle();
                    if (!context.mounted) return;
                    // force rebuild of just this FutureBuilder by using setState
                    setState(() {});
                  },
                );
              },
            ),
          ValueListenableBuilder<bool>(
            valueListenable: Perf.perfMode,
            builder: (context, on, _) => IconButton(
              tooltip: on ? 'Performance Mode: ON' : 'Performance Mode: OFF',
              icon: Icon(on ? Icons.speed_rounded : Icons.speed_outlined),
              onPressed: () => Perf.setPerfMode(!on),
            ),
          )
        ],
        ),
  body: RepaintBoundary(
        // Prevent global repaints when only timer text changes.
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                borderRadius: 24,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _TimerDisplay(secondsListenable: _secondsVN)),
                        if (_timerMode == TimerMode.countdown)
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
                                tooltip: 'Increase minutes',
                                onPressed: () {
                                  if (_isRunning) return;
                                  setState(() {
                                    final next = ((_totalSeconds ~/ 60) + 1).clamp(0, 24 * 60);
                                    _initialCountdownSeconds = next * 60;
                                    _totalSeconds = _initialCountdownSeconds;
                                  });
                                  // ensure UI text updates immediately
                                  _secondsVN.value = _totalSeconds;
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                                tooltip: 'Decrease minutes',
                                onPressed: () {
                                  if (_isRunning) return;
                                  setState(() {
                                    final next = ((_totalSeconds ~/ 60) - 1).clamp(0, 24 * 60);
                                    _initialCountdownSeconds = next * 60;
                                    _totalSeconds = _initialCountdownSeconds;
                                  });
                                  // ensure UI text updates immediately
                                  _secondsVN.value = _totalSeconds;
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timerMode == TimerMode.stopwatch ? 'Stopwatch' : 'Countdown',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Center(
                  child: ToggleButtons(
                    isSelected: [
                      _timerMode == TimerMode.stopwatch,
                      _timerMode == TimerMode.countdown,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _timerMode = index == 0 ? TimerMode.stopwatch : TimerMode.countdown;
                        if (_timerMode == TimerMode.countdown) {
                          // If first time switching or no minutes set, default to 25:00
                          if (_initialCountdownSeconds == 0) {
                            _initialCountdownSeconds = 25 * 60;
                          }
                          _totalSeconds = _initialCountdownSeconds;
                        } else {
                          _totalSeconds = 0;
                        }
                        _isRunning = false;
                        _timer?.cancel();
                      });
                      // sync display with new total seconds
                      _secondsVN.value = _totalSeconds;
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('Stopwatch')),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('Countdown')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GlassButton(
                    onPressed: _isRunning ? _stopTimer : _startTimer,
                    borderRadius: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(_isRunning ? 'Pause' : 'Start'),
                      ],
                    ),
                  ),
                  GlassButton(
                    onPressed: _resetTimer,
                    borderRadius: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.replay_rounded, size: 24),
                        SizedBox(width: 8),
                        Text('Reset'),
                      ],
                    ),
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
                  Expanded(
                    child: GlassButton(
                      onPressed: _saveSessionToHistory,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Save Session'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StatsScreen()),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.bar_chart_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Statistics'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        ),
        ),
      );
  }

  // --- THIS IS THE CORRECTED WIDGET ---
  Widget _buildTomatoCounter(String name, String duration, int count, String type, int minutes) {
    return GlassContainer(
      onTap: () => _setTimerDuration(minutes),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 28),
            onPressed: () => _updateTomatoCount(type, -1),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => _updateTomatoCount(type, 1),
          ),
        ],
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final ValueListenable<int> secondsListenable;
  const _TimerDisplay({required this.secondsListenable});

  String _format(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int secs = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: secondsListenable,
      builder: (context, seconds, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          _format(seconds),
          textAlign: TextAlign.center,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ... no custom route; we rely on global PageTransitionsTheme for smooth transitions ...