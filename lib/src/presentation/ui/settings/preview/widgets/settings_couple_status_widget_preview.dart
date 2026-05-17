import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/widgets/cards/inline_failure_card_widget.dart';

import 'package:trocado/src/presentation/ui/settings/data/couple_card_presentation_data.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_invite_partner_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_connected_widget.dart';
import 'package:trocado/src/presentation/ui/settings/widgets/settings_couple_loading_widget.dart';

const _connected = CoupleCardPresentationData(
  currentUserInitial: 'G',
  partnerInitial: 'M',
  title: 'Gabriel & Marina',
  subtitle: 'Conectados há 4 meses',
);

const _connectedLongNames = CoupleCardPresentationData(
  currentUserInitial: 'G',
  partnerInitial: 'M',
  title: 'Gabriel Henrique & Marina Fernanda',
  subtitle: 'Conectados há 1 ano e 2 meses',
);

Widget _shell(Widget child) => Scaffold(
  body: SafeArea(
    child: Padding(padding: const .all(16.0), child: child),
  ),
);

@TrocadoPreview(group: 'Estados', name: 'Loading')
Widget previewLoading() => _shell(const SettingsCoupleLoadingWidget());

@TrocadoPreview(group: 'Estados', name: 'Sem parceiro (convite)')
Widget previewNone() => _shell(SettingsInvitePartnerWidget(onTap: () {}));

@TrocadoPreview(group: 'Estados', name: 'Conectado')
Widget previewConnected() =>
    _shell(SettingsCoupleConnectedWidget(data: _connected, onTap: () {}));

@TrocadoPreview(group: 'Estados', name: 'Conectado (nomes longos)')
Widget previewConnectedLongNames() => _shell(
  SettingsCoupleConnectedWidget(data: _connectedLongNames, onTap: () {}),
);

@TrocadoPreview(group: 'Estados', name: 'Falha')
Widget previewFailure() => _shell(
  InlineFailureCardWidget(
    message: 'Não foi possível carregar o status do casal.',
    onRetry: () {},
  ),
);
