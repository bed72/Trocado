import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/ui/couple/scan/preview/mocks/invite_lookup_mock.dart';
import 'package:trocado/src/presentation/ui/couple/scan/widgets/couple_scan_partner_preview_widget.dart';

Widget _shell(Widget child) => Scaffold(
  body: SafeArea(
    child: Padding(padding: const .all(16.0), child: child),
  ),
);

@TrocadoPreview(group: 'Scan', name: 'Partner Preview')
Widget previewPartner() =>
    _shell(CoupleScanPartnerPreviewWidget(partner: inviteLookupMock().partner));

@TrocadoPreview(group: 'Scan', name: 'Partner Preview — Nome longo')
Widget previewPartnerLongName() => _shell(
  CoupleScanPartnerPreviewWidget(
    partner: inviteLookupMock(
      partnerName: 'Marina Fernanda Albuquerque',
      partnerEmail: 'marina.fernanda.albuquerque@trocado.app',
    ).partner,
  ),
);
