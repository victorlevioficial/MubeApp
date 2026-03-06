import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/chat/domain/chat_content_analyzer.dart';

void main() {
  group('ChatContentAnalyzer', () {
    test('allows normal chat text', () {
      final result = ChatContentAnalyzer.analyze('Opa, bora ensaiar sexta?');

      expect(result.isSuspicious, false);
      expect(result.patterns, isEmpty);
      expect(result.channels, isEmpty);
    });

    test('blocks direct phone sharing', () {
      final result = ChatContentAnalyzer.analyze('(11) 98765-4321');

      expect(result.isSuspicious, true);
      expect(result.patterns, contains('phone'));
      expect(result.severity, ChatContentSeverity.high);
    });

    test('blocks contact intent with whatsapp', () {
      final result = ChatContentAnalyzer.analyze('me chama no whatsapp');

      expect(result.isSuspicious, true);
      expect(result.channels, contains('whatsapp'));
      expect(result.patterns, contains('channel:whatsapp'));
    });

    test('allows plain instagram context without contact intent', () {
      final result = ChatContentAnalyzer.analyze(
        'Vi seu video no instagram ontem, ficou muito bom.',
      );

      expect(result.isSuspicious, false);
    });

    test('blocks direct @handle sharing', () {
      final result = ChatContentAnalyzer.analyze('@meuuser');

      expect(result.isSuspicious, true);
      expect(result.patterns, contains('handle'));
    });

    test('blocks long sequence of number words with contact context', () {
      final result = ChatContentAnalyzer.analyze(
        'meu numero é nove oito sete seis cinco quatro',
      );

      expect(result.isSuspicious, true);
      expect(result.patterns, contains('number_words'));
      expect(result.severity, ChatContentSeverity.high);
    });

    test('blocks long sequence of number words without explicit context', () {
      final result = ChatContentAnalyzer.analyze(
        'nove oito sete seis cinco quatro tres dois',
      );

      expect(result.isSuspicious, true);
      expect(result.patterns, contains('number_words'));
    });

    test('allows normal age-related usage of number words', () {
      final result = ChatContentAnalyzer.analyze(
        'Toco desde os nove anos e faço dois shows por mês.',
      );

      expect(result.isSuspicious, false);
    });
  });
}
