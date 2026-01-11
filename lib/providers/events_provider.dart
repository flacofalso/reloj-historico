import 'package:flutter/foundation.dart';
import '../models/historical_event.dart';
import '../services/google_sheets_service.dart';

class EventsProvider with ChangeNotifier {
  final Map<String, HistoricalEvent> _minuteEvents = {};
  final Map<String, HistoricalEvent> _hourEvents = {};
  
  List<HistoricalEvent> _favoriteEvents = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  final GoogleSheetsService _sheetsService = GoogleSheetsService();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventsProvider() {
    loadEventsFromGoogleSheets();
  }

  Future<void> loadEventsFromGoogleSheets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final hourEvents = await _sheetsService.loadHourEvents();
      for (var event in hourEvents) {
        _hourEvents[event.time] = event;
      }
      
      final minuteEvents = await _sheetsService.loadMinuteEvents();
      for (var event in minuteEvents) {
        _minuteEvents[event.time] = event;
      }
      
      print('✅ Loaded ${_hourEvents.length} hour events');
      print('✅ Loaded ${_minuteEvents.length} minute events');
      
    } catch (e) {
      _errorMessage = 'Error al cargar eventos: $e';
      print('❌ Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  HistoricalEvent? getEventByTime(String timeKey) {
    if (_minuteEvents.containsKey(timeKey)) {
      return _minuteEvents[timeKey];
    }
    
    final hourKey = '${timeKey.substring(0, 2)}:00';
    if (_hourEvents.containsKey(hourKey)) {
      return _hourEvents[hourKey];
    }
    
    return null;
  }

  List<HistoricalEvent> get favoriteEvents => _favoriteEvents;

  bool isFavorite(String eventId) {
    return _favoriteEvents.any((event) => event.id == eventId);
  }

  void toggleFavorite(HistoricalEvent event) {
    if (isFavorite(event.id)) {
      _favoriteEvents.removeWhere((e) => e.id == event.id);
    } else {
      _favoriteEvents.add(event);
    }
    notifyListeners();
  }

  Future<void> refreshEvents() async {
    _minuteEvents.clear();
    _hourEvents.clear();
    await loadEventsFromGoogleSheets();
  }
}