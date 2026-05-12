import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/domain/models/notification/notification_model.dart';

import 'package:trocado/src/presentation/ui/notifications/widgets/notification_card_widget.dart';

class NotificationsLoadingWidget extends StatelessWidget {
  const NotificationsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: Column(
      mainAxisSize: .min,
      children: .generate(
        8,
        (_) => const NotificationCardWidget(notification: _placeholder),
      ),
    ),
  );
}

const _placeholder = NotificationModel(
  id: 0,
  createdAt: 0,
  type: .unknown,
  title: 'Carregando título da notificação',
  description: 'Carregando descrição da notificação que pode ter duas linhas.',
);
