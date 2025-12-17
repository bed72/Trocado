import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/modules/calculator/presentation/stores/calculator_store.dart';
import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late CalculatorStore store;
  late ICalculatorRepository repository;

  setUp(() {
    repository = MockCalculatorRepository();
    store = CalculatorStore(repository: repository);
  });

  group('CalculatorStore - Digitação e Edição', () {
    test('Deve adicionar caracteres ao amount e atualizar preview', () {
      when(() => repository('12+2')).thenReturn(14.0);

      store.onKeyTap('1');
      store.onKeyTap('2');
      store.onKeyTap('+');
      store.onKeyTap('2');

      expect(store.amount, '12+2');
      expect(store.preview, '14');
      verify(() => repository('12+2')).called(1);
    });

    test('Deve limpar tudo ao clicar em AC', () {
      store.amount = '123';
      store.onKeyTap('AC');

      expect(store.amount, '');
      expect(store.preview, '...');
    });

    test('Deve deletar o último caractere', () {
      when(() => repository('1')).thenReturn(1.0);

      store.amount = '12';
      store.onKeyTap('DEL');

      expect(store.amount, '1');
      verify(() => repository('1')).called(1);
    });
  });

  group('CalculatorStore - Lógica de Parênteses', () {
    test('Deve alternar parênteses corretamente', () {
      when(() => repository(any())).thenReturn(double.nan);

      store.onKeyTap('()');
      expect(store.amount, '(');

      store.onKeyTap('1');
      store.onKeyTap('()');
      expect(store.amount, '(1)');

      store.onKeyTap('()');
      expect(store.amount, '(1)(');
    });
  });

  group('CalculatorStore - Resultado (Apply)', () {
    test('Deve aplicar o resultado no amount ao clicar em =', () {
      when(() => repository('10+10')).thenReturn(20.0);

      store.amount = '10+10';
      store.onKeyTap('=');

      expect(store.amount, '20');
      expect(store.preview, '20');
    });

    test('Não deve alterar amount se o repositório retornar NaN no =', () {
      when(() => repository('10/')).thenReturn(double.nan);

      store.amount = '10/';
      store.onKeyTap('=');

      expect(store.amount, '10/');
    });
  });

  group('CalculatorStore - Formatação', () {
    test('Deve formatar .0 para inteiro na visualização', () {
      when(() => repository('5+5')).thenReturn(10.0);

      store.append('5+5');

      expect(store.preview, '10');
    });

    test('Deve manter casas decimais se não for .0', () {
      when(() => repository('10/4')).thenReturn(2.5);

      store.append('10/4');

      expect(store.preview, '2.5');
    });
  });
}
