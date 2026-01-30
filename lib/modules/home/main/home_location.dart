import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/exit/exit.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/home/presentation/cubits/home_cubit.dart';
import 'package:trocado/modules/home/presentation/screens/home_screen.dart';

final class HomeLocation extends Location {
  @override
  String get path => RoutesConstant.home.path;

  @override
  LocationBuilder? get builder => (context) {
    quickAction(action: (_) => context.navigate(TransactionLocation()));

    return HomeScreen(
      dateCubit: context.get<DateCubit>(),
      homeCubit: context.get<HomeCubit>(),
      transactionCubit: context.get<TransactionCubit>(),
      onNavigateToExit: () => context.navigate(ExitLocation()),
      onPress: (id) => context.navigate(TransactionLocation(id: id)),
      onNavigateToTransaction: () => context.navigate(TransactionLocation()),
    );
  };
}
