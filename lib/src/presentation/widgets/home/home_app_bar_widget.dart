import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/notifiers/home/home_notifier.dart';
import 'package:trocado/src/presentation/widgets/home/month/month_selector_widget.dart';

class HomeAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      toolbarHeight: 56.0,
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
  Size get preferredSize => const Size.fromHeight(56.0);
}
