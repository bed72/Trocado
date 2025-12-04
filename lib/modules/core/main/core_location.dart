import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/home/home.dart';
import 'package:trocado/modules/report/report.dart';
import 'package:trocado/modules/settings/settings.dart';
import 'package:trocado/modules/transactions/transactions.dart';

import 'package:trocado/modules/core/domain/constant/routes_constant.dart';
import 'package:trocado/modules/core/domain/constant/bottom_bar_constant.dart';
import 'package:trocado/modules/core/domain/constant/quick_actions_constant.dart';

import 'package:trocado/modules/core/presentation/actions/quick_actions.dart';
import 'package:trocado/modules/core/presentation/commands/bottom_bar_command.dart';
import 'package:trocado/modules/core/presentation/builders/listenables_builder.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';
import 'package:trocado/modules/core/presentation/notifiers/bottom_bar_notifier.dart';
import 'package:trocado/modules/core/presentation/widgets/bottons/bottom_bar_widget.dart';

final class CoreLocation extends StatefulLocation {
  @override
  String get path => RoutesConstant.core.path;

  @override
  List<Location> get children => [
    HomeLocation(),
    AllTransactionsLocation(),
    TransactionLocation(),
    ReportLocation(),
    SettingsLocation(),
  ];

  @override
  StatefulLocationBuilder get childBuilder => (context, shell) {
    final bottom = context.get<BottomBarCommand>();

    return ConsumerBuilder<int, int>(
      command: bottom.command,
      data: (_, index, _) {
        quickAction(
          action: (type) {
            context.navigate(
              TypeTransactionLocation(
                title: type == QuickActionsConstant.input.name
                    ? QuickActionsConstant.input.localizedTitle
                    : QuickActionsConstant.output.localizedTitle,
              ),
              root: true,
            );
          },
        );

        return Scaffold(
          body: shell,
          bottomNavigationBar: SafeArea(
            top: false,
            child: BottomBarWidget(
              index: index,
              onExit: context.exit,
              onTap: ({required context, required index}) {
                if (index == BottomBarConstant.transaction.position) {
                  return transactionBottomSheetFactoryWidget(context);
                }

                shell.switchChild(index);
                bottom.command(index);
              },
            ),
          ),
        );
      },
    );
  };
}
