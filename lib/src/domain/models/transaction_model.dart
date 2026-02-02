import 'package:equatable/equatable.dart';
import 'package:trocado/src/domain/models/category_model.dart';

enum TransactionTypeModel {
  income('Receita'),
  expense('Despesa');

  final String label;
  const TransactionTypeModel(this.label);

  static TransactionTypeModel fromByString(String value) => .values.firstWhere(
    (transaction) => transaction.label == value,
    orElse: () => .expense,
  );
}

final class TransactionModel extends Equatable {
  final int date;
  final String type;
  final double amount;
  final String category;
  final String description;

  final int? id;
  final String? observation;

  const TransactionModel({
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.id,
    this.observation,
  });

  @override
  List<Object?> get props => [
    id,
    date,
    type,
    amount,
    category,
    description,
    observation,
  ];

  factory TransactionModel.empty({DateTime? date}) => TransactionModel(
    id: null,
    amount: 0,
    description: '',
    observation: null,
    category: CategoryModel.other.label,
    type: TransactionTypeModel.expense.label,
    date: DateTime.now().millisecondsSinceEpoch,
  );

  TransactionModel copyWith({
    int? id,
    int? date,
    String? type,
    double? amount,
    String? category,
    String? description,
    String? observation,
  }) => TransactionModel(
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
      'type: $type, '
      'date: $date, '
      'amount: $amount, '
      'category: $category, '
      'observation: $observation, '
      'description: $description,'
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
