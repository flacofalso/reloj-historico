import 'dart:async';
import 'package:flutter/foundation.dart';

class ClockProvider with ChangeNotifier {
  DateTime _currentTime = DateTime.now();
  bool _isManualMode = false;
  bool _isAnalogMode = false;
  Timer? _timer;

  DateTime get currentTime => _currentTime;
  bool get isManualMode => _isManualMode;
  bool get isAnalogMode => _isAnalogMode;

  ClockProvider() {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isManualMode) {
        _currentTime = DateTime.now();
        notifyListeners();
      }
    });
  }

  void toggleClockMode() {
    _isAnalogMode = !_isAnalogMode;
    notifyListeners();
  }

  void toggleManualMode() {
    _isManualMode = !_isManualMode;
    if (!_isManualMode) {
      _currentTime = DateTime.now();
    }
    notifyListeners();
  }

  void navigateTime(int minutes) {
    _isManualMode = true;
    _currentTime = _currentTime.add(Duration(minutes: minutes));
    notifyListeners();
  }

  void setTime(DateTime time) {
    _isManualMode = true;
    _currentTime = time;
    notifyListeners();
  }

  String getTimeKey() {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}