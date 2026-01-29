import 'package:trocado/modules/category/category.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';

final class TransactionDto {
  final DateTime date;
  final String description;
  final CategoryDto category;
  final TransactionTypeDto type;

  final int? id;
  final double? amount;
  final String? observation;

  TransactionDto({
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.id,
    this.observation,
  });

  factory TransactionDto.empty({DateTime? date}) => TransactionDto(
    id: null,
    amount: null,
    type: .expense,
    description: '',
    category: .other,
    observation: null,
    date: date ?? DateTime.now(),
  );

  TransactionDto copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? description,
    String? observation,
    CategoryDto? category,
    TransactionTypeDto? type,
  }) => TransactionDto(
    id: id ?? this.id,
    date: date ?? this.date,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    description: description ?? this.description,
    observation: observation ?? this.observation,
  );

  @override
  String toString() =>
      'TransactionDto('
      'date: $date, '
      'amount: $amount, '
      'type: ${type.name}, '
      'observation: $observation, '
      'description: $description, '
      'category: ${category.name}'
      ')';

  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Adicione uma descrição.';
    }

    final trimmed = value.trim();
    final regex = RegExp(r'^[A-Za-zÀ-ÿ\s]{3,}$');

    return !regex.hasMatch(trimmed) ? 'Use ao menos 3 letras.' : null;
  }

  String? validateAmount({
    required String? value,
    required double Function(String) parse,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Adicione um valor.';
    }

    final parsed = parse(value);

    return (parsed <= 0) ? 'Adicione um valor válido' : null;
  }
}
