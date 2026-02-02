import 'package:duck_router/duck_router.dart';

import 'package:trocado/src/domain/constants/routes_constant.dart';

import 'package:trocado/src/main/locations/exit_location.dart';
import 'package:trocado/src/main/locations/transaction_location.dart';

import 'package:trocado/src/presentation/actions/quick_action.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/screens/home_screen.dart';
import 'package:trocado/src/presentation/cubits/date/date_cubit.dart';
import 'package:trocado/src/presentation/cubits/home/home_cubit.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';

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
