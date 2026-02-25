import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';
import 'package:trocado/src/main/locations/budget_location.dart';

import 'package:trocado/src/main/locations/exit_location.dart';
import 'package:trocado/src/main/locations/expense_location.dart';

import 'package:trocado/src/presentation/screens/home_screen.dart';
import 'package:trocado/src/presentation/actions/quick_action.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

final class HomeLocation extends Location {
  @override
  String get path => AppRoutes.home.path;

  @override
  LocationBuilder? get builder => (context) {
    quickAction(
      action: (type) {
        context.navigate(
          type == QuickActionsConstant.budget.name
              ? BudgetLocation()
              : ExpenseLocation(),
        );
      },
    );

    return HomeScreen(
      onNavigateToExit: () => context.navigate(ExitLocation()),
      onPress: (id) => context.navigate(ExpenseLocation(id: id)),
      onNavigateToBudget: () => context.navigate(BudgetLocation()),
      onNavigateToExpense: () => context.navigate(ExpenseLocation()),
    );
  };
}
