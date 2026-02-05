import 'package:objectbox/objectbox.dart';

@Entity()
final class TransactionEntity {
  final int date;
  final String type;
  final double amount;
  final String category;
  final String description;

  @Id()
  int? id;
  final String? observation;

  TransactionEntity({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.observation,
  });
}
