import 'package:rearch/rearch.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/presentation/capsules/amount_capsule.dart';
import 'package:trocado/src/presentation/data/ui/amount_presentation_data.dart';

void main() {
  late CapsuleContainer container;

  setUp(() {
    container = CapsuleContainer();
  });

  tearDown(() {
    container.dispose();
  });

  String normalize(String value) => value.replaceAll('\u00A0', ' ');
  String readFormatted() => normalize(container.read(amountCapsule).$1);

  void onChange(AmountPresentationData data) =>
      container.read(amountCapsule).$2(data);

  test('should start with zero amount formatted', () {
    expect(readFormatted(), 'R\$ 0,00');
  });

  test('should append digit when digit action is received', () {
    onChange(AmountPresentationData.digit('1'));

    expect(readFormatted(), 'R\$ 0,01');

    onChange(AmountPresentationData.digit('2'));

    expect(readFormatted(), 'R\$ 0,12');
  });

  test('should remove last digit when delete action is received', () {
    onChange(AmountPresentationData.digit('5'));
    onChange(AmountPresentationData.digit('0'));

    expect(readFormatted(), 'R\$ 0,50');

    onChange(AmountPresentationData.delete());

    expect(readFormatted(), 'R\$ 0,05');
  });

  test('should reset amount when clear action is received', () {
    onChange(AmountPresentationData.digit('9'));
    onChange(AmountPresentationData.digit('9'));

    expect(readFormatted(), 'R\$ 0,99');

    onChange(AmountPresentationData.clear());

    expect(readFormatted(), 'R\$ 0,00');
  });

  test('submit action should not change the amount', () {
    onChange(AmountPresentationData.digit('3'));
    onChange(AmountPresentationData.digit('4'));

    expect(readFormatted(), 'R\$ 0,34');

    onChange(AmountPresentationData.submit());

    expect(readFormatted(), 'R\$ 0,34');
  });

  test('should handle a realistic user input sequence correctly', () {
    onChange(AmountPresentationData.digit('1'));
    onChange(AmountPresentationData.digit('2'));
    onChange(AmountPresentationData.digit('3'));

    expect(readFormatted(), 'R\$ 1,23');

    onChange(AmountPresentationData.delete());

    expect(readFormatted(), 'R\$ 0,12');

    onChange(AmountPresentationData.digit('9'));

    expect(readFormatted(), 'R\$ 1,29');

    onChange(AmountPresentationData.clear());

    expect(readFormatted(), 'R\$ 0,00');
  });
}
