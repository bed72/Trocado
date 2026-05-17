import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/presentation/ui/couple/invite/data/invite_qr_code_presentation_data.dart';
import 'package:trocado/src/presentation/ui/couple/invite/widgets/invite_qr_card_widget.dart';

class InviteQrCodeLoadingWidget extends StatelessWidget {
  const InviteQrCodeLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => const Skeletonizer(
    enabled: true,
    child: InviteQrCardWidget(
      data: InviteQrCodePresentationData(
        code: 'AAAAAA',
        qrData: 'trocado://invite/AAAAAA',
        formattedExpiration: 'Expira em 00/00 às 00:00',
      ),
    ),
  );
}
