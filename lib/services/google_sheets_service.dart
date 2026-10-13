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
  
  List<HistoricalEvent> _parseCsvToEvents(String csvData) => parseEvents(csvData);

  static List<HistoricalEvent> parseEvents(String csvData) {
    final events = <HistoricalEvent>[];
    final rows = parseCsv(csvData);

    for (int i = 1; i < rows.length; i++) {
      final values = rows[i].map((v) => v.trim()).toList();
      if (values.length < 8 || values[0].isEmpty) continue;

      events.add(HistoricalEvent(
        id: 'gs-${values[0]}-$i',
        time: normalizeTime(values[0]),
        date: values[1],
        title: values[2],
        description: values[3],
        category: values[4],
        imageUrl: values[5],
        source: values[6],
        verified: values[7].toUpperCase() == 'TRUE',
      ));
    }

    return events;
  }

  // CSV estándar: campos entre comillas, "" como comilla escapada y saltos de línea dentro de un campo
  static List<List<String>> parseCsv(String csvData) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var insideQuotes = false;

    for (int i = 0; i < csvData.length; i++) {
      final char = csvData[i];

      if (insideQuotes) {
        if (char == '"') {
          if (i + 1 < csvData.length && csvData[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            insideQuotes = false;
          }
        } else {
          field.write(char);
        }
      } else if (char == '"') {
        insideQuotes = true;
      } else if (char == ',') {
        row.add(field.toString());
        field.clear();
      } else if (char == '\n') {
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else if (char != '\r') {
        field.write(char);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  // La planilla puede traer "8:46" o "08:46"; la app busca siempre "HH:mm"
  static String normalizeTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return value;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
