import 'package:objectbox/objectbox.dart';

@Entity()
final class TransactionEntity {
  @Id()
  int id = 0;
  final int date;
  final String type;
  final double amount;
  final String category;
  final String description;
  final String? observation;

  TransactionEntity({
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    this.observation,
  });
}
