import 'package:objectbox/objectbox.dart';

@Entity()
final class ExpenseEntity {
  final int date;
  final double amount;
  final String category;
  final String description;

  @Id()
  int? id;

  ExpenseEntity({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
  });
}
