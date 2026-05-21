import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/ui/home/widgets/home_app_bar_widget.dart';
import 'package:trocado/src/presentation/ui/home/data/home_app_bar_presentation_data.dart';

const _solo = HomeAppBarSoloPresentationData(name: 'Gabriel Ramos');

const _couple = HomeAppBarCouplePresentationData(
  currentInitial: 'G',
  partnerInitial: 'K',
  title: 'Gabriel & Kira',
);

const _coupleLongNames = HomeAppBarCouplePresentationData(
  currentInitial: 'G',
  partnerInitial: 'M',
  title: 'Gabriel & Maria Eduarda',
);

Widget _shell(AsyncValue<HomeAppBarPresentationData> state) => Scaffold(
  appBar: HomeAppBarWidget(
    appBarState: state,
    themeMode: .system,
    onCycleTheme: () {},
    navigateToProfile: () {},
    navigateToSettings: () {},
    navigateToNotification: () {},
  ),
  body: const SizedBox.shrink(),
);

@TrocadoPreview(group: 'Estados', name: 'Loading')
Widget previewLoading() => _shell(const AsyncLoading());

@TrocadoPreview(group: 'Estados', name: 'Solo')
Widget previewSolo() => _shell(const AsyncData(_solo));

@TrocadoPreview(group: 'Estados', name: 'Couple')
Widget previewCouple() => _shell(const AsyncData(_couple));

@TrocadoPreview(group: 'Estados', name: 'Couple - Long Names')
Widget previewCoupleLongNames() =>
    _shell(const AsyncData(_coupleLongNames));
