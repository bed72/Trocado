import 'package:duck_router/duck_router.dart';

import 'package:trocado/app_route.dart';

import 'package:trocado/src/presentation/pages/bottom_sheet_page.dart';
import 'package:trocado/src/presentation/screens/date_range/screens/date_range_screen.dart';

final class DateRangeLocation extends Location {
  final String? title;
  final String? subtitle;
  final int? initialStartDate;
  final int? initialEndDate;
  final DateRangeSelected onSelected;

  const DateRangeLocation({
    required this.onSelected,
    this.title,
    this.subtitle,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  String get path => AppRoutes.dateRange.path;

  @override
  LocationPageBuilder get pageBuilder => (_) => BottomSheetPage(
    builder: (_) => DateRangeScreen(
      onSelected: onSelected,
      title: title ?? 'Período',
      subtitle: subtitle ?? 'Selecione o período.',
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
    ),
  );
}
