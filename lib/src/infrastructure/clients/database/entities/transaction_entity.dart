import 'package:objectbox/objectbox.dart';

@Entity()
final class TransactionEntity {
  final int date;
  final double amount;
  final String category;
  final String description;

  @Id()
  int? id;

  TransactionEntity({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
  });
}
