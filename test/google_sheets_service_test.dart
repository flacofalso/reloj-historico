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

  group('parseEvents', () {
    const header =
        '"Hora","Fecha","Título","Descripción","Categoría","ImagenURL","Fuente","Verificado"';

    test('respeta comillas escapadas, apóstrofes y comas dentro de un campo', () {
      const csv = '$header\n'
          '"8:46","2001-09-11","Título","Dijo ""Let\'s roll"", y siguió","Terrorismo","img","Fuente","TRUE"';
      final events = GoogleSheetsService.parseEvents(csv);
      expect(events, hasLength(1));
      expect(events.first.time, '08:46');
      expect(events.first.description, 'Dijo "Let\'s roll", y siguió');
      expect(events.first.verified, isTrue);
    });

    test('acepta saltos de línea dentro de un campo y finales CRLF', () {
      const csv = '$header\r\n'
          '"23:40","1912-04-14","Titanic","Línea 1\nLínea 2","Desastre","img","","FALSE"\r\n'
          '"02:20","1912-04-15","Hundimiento","Texto","Desastre","img","","TRUE"\r\n';
      final events = GoogleSheetsService.parseEvents(csv);
      expect(events.map((e) => e.time), ['23:40', '02:20']);
      expect(events.first.description, 'Línea 1\nLínea 2');
      expect(events.first.verified, isFalse);
    });

    test('ignora filas vacías o incompletas', () {
      const csv = '$header\n\n"10:00","x"\n';
      expect(GoogleSheetsService.parseEvents(csv), isEmpty);
    });
  });
}
