import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/category/category.dart';

import 'package:trocado/modules/transaction/data/dtos/transaction_type_dto.dart';
import 'package:trocado/modules/transaction/domain/models/transaction_model.dart';

final class TransactionDto {
  final String amount;
  final DateTime date;
  final String description;
  final CategoryDto category;
  final TransactionTypeDto type;

  final int? id;
  final String? observation;

  const TransactionDto({
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.id,
    this.observation,
  });

  factory TransactionDto.empty() => TransactionDto(
    id: null,
    amount: '',
    type: .expense,
    description: '',
    category: .other,
    observation: null,
    date: DateTime.now(),
  );

  factory TransactionDto.toDto(TransactionModel data) => TransactionDto(
    description: data.description,
    type: .fromByString(data.type),
    amount: data.amount.toString(),
    category: .fromByString(data.category),
    date: dateTimeFromMilliseconds(data.date),
  );

  TransactionDto copyWith({
    int? id,
    String? amount,
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

  String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Adicione um valor.';
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));

    return (parsed == null || parsed <= 0) ? 'Adicione um valor válido' : null;
  }
}
