import 'package:flutter/widgets.dart';

import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/domain/models/home_model.dart';
import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

class HomeSuccessWidget extends StatelessWidget {
  final HomeModel data;
  final ValueChanged<TransactionDto> onPress;
  final TransactionDto Function(TransactionModel) toDto;

  const HomeSuccessWidget({
    super.key,
    required this.data,
    required this.toDto,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const .symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: data.transactions.length,
          (_, index) => TransactionWidget(
            onPress: onPress,
            dto: toDto(data.transactions[index]),
          ),
        ),
      ),
    );
  }
}
