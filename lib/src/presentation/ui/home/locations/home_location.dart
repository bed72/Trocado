import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/ui/exit/locations/exit_location.dart';
import 'package:trocado/src/presentation/ui/expense/locations/expense_location.dart';
import 'package:trocado/src/presentation/ui/expenses/locations/expenses_location.dart';

import 'package:trocado/src/presentation/actions/quick_action.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/ui/home/screens/home_screen.dart';
import 'package:trocado/src/presentation/ui/budget/locations/budget_location.dart';
import 'package:trocado/src/presentation/ui/profile/details/locations/profile_details_location.dart';
import 'package:trocado/src/presentation/ui/budgets/locations/budgets_location.dart';
import 'package:trocado/src/presentation/ui/settings/locations/settings_location.dart';
import 'package:trocado/src/presentation/ui/notifications/locations/notifications_location.dart';

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
      navigateToChat: () {},
      navigateToExit: () => context.navigate(ExitLocation()),
      navigateToBudget: () => context.navigate(BudgetLocation()),
      navigateToProfile: () => context.navigate(ProfileDetailsLocation()),
      navigateToBudgets: () => context.navigate(BudgetsLocation()),
      navigateToExpenses: () => context.navigate(ExpensesLocation()),
      navigateToSettings: () => context.navigate(SettingsLocation()),
      navigateToCreateExpense: () => context.navigate(ExpenseLocation()),
      navigateToNotification: () => context.navigate(NotificationsLocation()),
    );
  };
}
