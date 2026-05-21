import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/ui/couple/scan/formatters/uppercase_alphabet_formatter.dart';

TextEditingValue _value(String text) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

void main() {
  final formatter = UppercaseAlphabetFormatter();

  group('UppercaseAlphabetFormatter', () {
    test('uppercases lowercase input', () {
      final data = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _value('ab3k7n'),
      );

      expect(data.text, 'AB3K7N');
    });

    test('keeps already valid uppercase input as-is', () {
      final data = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _value('AB3K7N'),
      );

      expect(data.text, 'AB3K7N');
    });

    test('strips ambiguous characters (I, O, 0, 1)', () {
      final data = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _value('IO01AB'),
      );

      expect(data.text, 'AB');
    });

    test('strips punctuation and whitespace', () {
      final data = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _value('AB-3 K7!'),
      );

      expect(data.text, 'AB3K7');
    });

    test('collapses selection to end of filtered text', () {
      final data = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'ab-3k7',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );

      expect(data.text, 'AB3K7');
      expect(data.selection, const TextSelection.collapsed(offset: 5));
    });
  });
}
