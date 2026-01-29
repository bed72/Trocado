import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/presentation/widgets/month/month_selector_widget.dart';

class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final HomeCubit cubit;

  const HomeAppBarWidget({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      toolbarHeight: 72.0,
      title: BlocBuilder<HomeCubit, HomeState>(
        bloc: cubit,
        buildWhen: (previous, current) =>
            (previous is HomeSuccess && current is HomeSuccess)
            ? previous.month != current.month
            : true,
        builder: (_, state) {
          final month = state is HomeSuccess ? state.month : cubit.currentMonth;

          return MonthSelectorWidget(
            month: month,
            onNext: cubit.nextMonth,
            onPrevious: cubit.previousMonth,
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72.0);
}
