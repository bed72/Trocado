import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/data/mapper/expense_mapper.dart';

import 'package:trocado/src/domain/services/interface_money_repository.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/main/providers.dart';
import 'package:trocado/src/presentation/themes/themes.dart';
import 'package:trocado/src/presentation/widgets/load_widget.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';

final class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers(),
      child: Builder(
        builder: (context) => BlocProvider(
          lazy: true,
          create: (context) => ExpenseFormBloc(
            service: context.read<IMoneyService>(),
            repository: context.read<IExpenseRepository>(),
            mapper: context.read<ExpensePresentationToModelMapper>(),
          ),
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
      ),
    );
  }
}
