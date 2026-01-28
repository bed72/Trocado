import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/presentation/widgets/home_success_widget.dart';
import 'package:trocado/modules/home/presentation/widgets/home_loading_widget.dart';

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
          onPress: (value) {},
          format: cubit.format,
          model: state.home.balance,
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
