import 'package:trocado/modules/calculator/calculator.dart';

final class CalculatorRepository implements ICalculatorRepository {
  final _operators = {'+', '-', '*', '/'};
  final _precedence = {'+': 1, '-': 1, '*': 2, '/': 2};

  @override
  bool isInvalidFirstInput(String expression) {
    if (expression.isEmpty) return true;

    return _operators.contains(expression[0]);
  }

  @override
  double call(String data) {
    try {
      final expr = _sanitize(data);

      if (isInvalidFirstInput(expr)) return double.nan;

      return _evaluate(expr);
    } catch (_) {
      return double.nan;
    }
  }

  bool _isDigit(String char) => '0123456789.'.contains(char);

  bool _isOperator(String token) => _operators.contains(token);

  bool _isNumber(String token) => double.tryParse(token) != null;

  double _evaluate(String expr) {
    final tokens = _tokenize(expr);
    final reversePolishNotation = _toReversePolishNotation(tokens);

    return _evalReversePolishNotation(reversePolishNotation);
  }

  String _sanitize(String input) =>
      input.replaceAll('×', '*').replaceAll('÷', '/');

  void _flushBuffer(StringBuffer buffer, List<String> tokens) {
    if (buffer.isEmpty) return;

    tokens.add(buffer.toString());
    buffer.clear();
  }

  void _drainUntilOpenParenthesis(List<String> ops, List<String> output) {
    while (ops.isNotEmpty && ops.last != '(') {
      output.add(ops.removeLast());
    }

    ops.removeLast();
  }

  void _drainOperators(String current, List<String> ops, List<String> output) {
    while (ops.isNotEmpty &&
        _isOperator(ops.last) &&
        _precedence[ops.last]! >= _precedence[current]!) {
      output.add(ops.removeLast());
    }
  }

  double _applyOperator(String op, double a, double b) => switch (op) {
    '+' => a + b,
    '-' => a - b,
    '*' => a * b,
    '/' => a / b,
    _ => throw UnsupportedError('Invalid operator: $op'),
  };

  double _evalReversePolishNotation(List<String> reversePolishNotation) {
    final stack = <double>[];

    for (final token in reversePolishNotation) {
      if (_isNumber(token)) {
        stack.add(double.parse(token));
        continue;
      }

      final b = stack.removeLast();
      final a = stack.removeLast();

      stack.add(_applyOperator(token, a, b));
    }

    return stack.single;
  }

  List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (final char in expr.split('')) {
      if (_isDigit(char)) {
        buffer.write(char);
        continue;
      }

      _flushBuffer(buffer, tokens);
      tokens.add(char);
    }

    _flushBuffer(buffer, tokens);
    return tokens;
  }

  List<String> _toReversePolishNotation(List<String> tokens) {
    final ops = <String>[];
    final output = <String>[];

    for (final token in tokens) {
      if (_isNumber(token)) {
        output.add(token);
        continue;
      }

      if (_isOperator(token)) {
        _drainOperators(token, ops, output);
        ops.add(token);
        continue;
      }

      if (token == '(') {
        ops.add(token);
        continue;
      }

      if (token == ')') _drainUntilOpenParenthesis(ops, output);
    }

    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }

    return output;
  }
}
