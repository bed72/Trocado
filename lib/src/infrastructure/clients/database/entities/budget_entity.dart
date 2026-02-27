import 'package:objectbox/objectbox.dart';

@Entity()
final class BudgetEntity {
  @Id()
  int? id;

  final double amount;
  final int startDate;
  final int endDate;
  final String? description;

  BudgetEntity({
    required this.id,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.description,
  });
}
