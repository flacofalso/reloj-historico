import 'package:flutter_test/flutter_test.dart';
import 'package:historical_clock/services/google_sheets_service.dart';

void main() {
  group('normalizeTime', () {
    test('agrega el cero a horas de un dígito', () {
      expect(GoogleSheetsService.normalizeTime('0:15'), '00:15');
      expect(GoogleSheetsService.normalizeTime('8:46'), '08:46');
    });

    test('deja intactas las horas que ya tienen dos dígitos', () {
      expect(GoogleSheetsService.normalizeTime('10:03'), '10:03');
      expect(GoogleSheetsService.normalizeTime('00:00'), '00:00');
    });

    test('ignora segundos y espacios', () {
      expect(GoogleSheetsService.normalizeTime(' 1:23:45 '), '01:23');
    });

    test('devuelve el valor original si no es una hora', () {
      expect(GoogleSheetsService.normalizeTime(''), '');
      expect(GoogleSheetsService.normalizeTime('sin hora'), 'sin hora');
    });
  });
}
