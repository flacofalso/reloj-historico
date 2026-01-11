import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/historical_event.dart';

class GoogleSheetsService {
  // ⚠️ REEMPLAZA CON TU ID DE GOOGLE SHEET
  static const String spreadsheetId = '1TdXNlzU3ofoM9FyzBiQaHNyeZosisg2IksE-IzNMXLc';
  
  static const String hourEventsSheet = 'EventosPorHora';
  static const String minuteEventsSheet = 'EventosPorMinutos';
  
  Future<List<HistoricalEvent>> loadHourEvents() async {
    try {
      final url = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:csv&sheet=$hourEventsSheet';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return _parseCsvToEvents(response.body);
      } else {
        print('Error loading hour events: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception loading hour events: $e');
      return [];
    }
  }
  
  Future<List<HistoricalEvent>> loadMinuteEvents() async {
    try {
      final url = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:csv&sheet=$minuteEventsSheet';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return _parseCsvToEvents(response.body);
      } else {
        print('Error loading minute events: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception loading minute events: $e');
      return [];
    }
  }
  
  List<HistoricalEvent> _parseCsvToEvents(String csvData) {
    final events = <HistoricalEvent>[];
    
    try {
      final lines = csvData.split('\n');
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final values = _parseCsvLine(line);
        
        if (values.length >= 8) {
          final event = HistoricalEvent(
            id: 'gs-${values[0]}-$i',
            time: _cleanValue(values[0]),
            date: _cleanValue(values[1]),
            title: _cleanValue(values[2]),
            description: _cleanValue(values[3]),
            category: _cleanValue(values[4]),
            imageUrl: _cleanValue(values[5]),
            source: values.length > 6 ? _cleanValue(values[6]) : '',
            verified: values.length > 7 ? _cleanValue(values[7]).toUpperCase() == 'TRUE' : false,
          );
          
          events.add(event);
        }
      }
    } catch (e) {
      print('Error parsing CSV: $e');
    }
    
    return events;
  }
  
  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    var currentValue = StringBuffer();
    var insideQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        values.add(currentValue.toString());
        currentValue = StringBuffer();
      } else {
        currentValue.write(char);
      }
    }
    
    values.add(currentValue.toString());
    return values;
  }
  
  String _cleanValue(String value) {
    return value.trim().replaceAll('"', '').replaceAll("'", '');
  }
}