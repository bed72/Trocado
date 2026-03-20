import 'package:duck_router/duck_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/category_screen.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';

final class CategoryLocation extends Location {
  @override
  String get path => AppRoutes.category.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(
        builder: (context) =>
            CategoryScreen(bloc: context.read<ExpenseFormBloc>()),
      );
}
