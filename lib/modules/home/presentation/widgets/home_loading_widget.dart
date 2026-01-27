import 'package:flutter/widgets.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/home/presentation/widgets/transaction/transaction_widget.dart';

class HomeLoadingWidget extends StatelessWidget {
  const HomeLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SkeletonWidget(
        child: Column(
          children: .generate(
            10,
            (_) => TransactionWidget(
              dto: .empty(),
              onPress: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );
  }
}
