import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/home/expense/expense_widget.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_state.dart';

class HomeSuccessWidget extends StatelessWidget {
  final ExpenseListState data;
  final ValueChanged<int?> navigatTo;

  const HomeSuccessWidget({
    super.key,
    required this.data,
    required this.navigatTo,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const .symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: data.expenses.length + (data.hasReachedMax ? 0 : 1),
            itemBuilder: (_, index) {
              if (index >= data.expenses.length) {
                return const Padding(
                  padding: .symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // final category = CategoryPresentationData.fromName(
              //   model.category,
              // );
              // final date = DateTime.fromMillisecondsSinceEpoch(model.date);

              return ExpenseWidget(
                navigatTo: navigatTo,
                data: data.expenses[index],
              );
              // ListTile(
              //   onTap: () => navigatTo(expense.id),
              //   leading: CircleAvatar(
              //     backgroundColor: category.color.withValues(alpha: 0.15),
              //     child: Icon(category.icon, color: category.color, size: 20),
              //   ),
              //   title: Text(
              //     expense.description,
              //     maxLines: 1,
              //     overflow: .ellipsis,
              //   ),
              //   subtitle: Text(
              //     '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
              //     style: context.typography.bodySmall,
              //   ),
              //   trailing: Text(
              //     'R\$ ${expense.amount.toStringAsFixed(2).replaceAll('.', ',')}',
              //     style: context.typography.bodyMedium?.copyWith(
              //       fontWeight: .w700,
              //     ),
              //   ),
              // );
            },
          ),
        ),
      ],
    );
  }
}
