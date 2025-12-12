import 'package:trocado/modules/calculator/domain/repositories/interface_calculator_repository.dart';

final class CalculatorRepository implements ICalculatorRepository {
  @override
  double call(String data) {
    final sanitized = data.replaceAll('×', '*').replaceAll('÷', '/');

    try {
      return _parseExpression(sanitized);
    } catch (_) {
      return double.nan;
    }
  }

  double _parseExpression(String expr) {
    final ops = <String>[];
    final output = <String>[];

    final prec = {'+': 1, '-': 1, '*': 2, '/': 2};

    final tokens = _tokenize(expr);

    for (final t in tokens) {
      if (_isNumber(t)) {
        output.add(t);
      } else if (prec.containsKey(t)) {
        while (ops.isNotEmpty &&
            prec.containsKey(ops.last) &&
            prec[ops.last]! >= prec[t]!) {
          output.add(ops.removeLast());
        }
        ops.add(t);
      } else if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        ops.removeLast();
      }
    }

    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }

    return _evalRPN(output);
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (final char in expr.split('')) {
      if ('0123456789.'.contains(char)) {
        buffer.write(char);
      } else {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  bool _isNumber(String s) => double.tryParse(s) != null;

  double _evalRPN(List<String> rpn) {
    final stack = <double>[];

    for (final token in rpn) {
      if (_isNumber(token)) {
        stack.add(double.parse(token));
      } else {
        final b = stack.removeLast();
        final a = stack.removeLast();

        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            stack.add(a / b);
            break;
        }
      }
    }

    return stack.single;
  }
}
