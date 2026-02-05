import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/notifiers/home/home_notifier.dart';
import 'package:trocado/src/presentation/widgets/home/home_success_widget.dart';
import 'package:trocado/src/presentation/widgets/home/home_loading_widget.dart';

class GridBalanceWidget extends StatelessWidget {
  final HomeCubit cubit;

  const GridBalanceWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      bloc: cubit,
      buildWhen: (_, current) =>
          current is HomeSuccess || current is HomeLoading,
      builder: (_, state) => switch (state) {
        HomeLoading() => HomeBalanceLoadingWidget(),
        HomeSuccess() => HomeBalaceSuccessWidget(
          type: cubit.selectedType,
          model: state.home.balance,
          onPress: (value) => cubit.filterBalanceBy(type: value),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
