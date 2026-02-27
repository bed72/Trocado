import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/main/injection.dart';
import 'package:trocado/src/presentation/themes/themes.dart';
import 'package:trocado/src/presentation/widgets/load_widget.dart';
import 'package:trocado/src/presentation/bloc/budget/budget_bloc.dart';
import 'package:trocado/src/presentation/bloc/budget/budget_event.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_list/expense_list_event.dart';

final class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(lazy: true, create: (_) => sl<ExpenseFormBloc>()),
        BlocProvider(
          create: (_) => sl<ExpenseListBloc>()..add(const ExpenseListStarted()),
        ),
        BlocProvider(
          create: (_) => sl<BudgetBloc>()..add(const BudgetLoaded()),
        ),
      ],
      child: BlocListener<ExpenseFormBloc, ExpenseFormState>(
        listenWhen: (prev, curr) => curr.status == ExpenseFormStatus.success,
        listener: (context, state) {
          context
              .read<ExpenseListBloc>()
              .add(const ExpenseListRefreshRequested());
          context.read<BudgetBloc>().add(const BudgetRecalculated());
        },
        child: MaterialApp.router(
          title: 'Trocado',
          theme: Themes.light,
          darkTheme: Themes.dark,
          routerConfig: routerConfig,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: kDebugMode,
          supportedLocales: const [Locale('pt', 'BR')],
          builder: (_, child) => LoadWidget(child: child),
          localizationsDelegates: const [
            GlobalWidgetsLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
