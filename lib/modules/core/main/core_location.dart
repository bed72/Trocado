import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/home/home.dart';
import 'package:trocado/modules/report/report.dart';
import 'package:trocado/modules/settings/settings.dart';
import 'package:trocado/modules/transactions/transactions.dart';

import 'package:trocado/modules/core/domain/constant/routes_constant.dart';
import 'package:trocado/modules/core/domain/constant/bottom_bar_constant.dart';
import 'package:trocado/modules/core/domain/constant/quick_actions_constant.dart';

import 'package:trocado/modules/core/presentation/actions/quick_actions.dart';
import 'package:trocado/modules/core/presentation/stores/bottom_bar_store.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';
import 'package:trocado/modules/core/presentation/widgets/bottom-bars/bottom_bar_widget.dart';

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
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Observer(
          builder: (context) {
            final store = context.get<BottomBarStore>();

            quickAction(
              action: (type) async {
                await transactionBottomSheetFactoryWidget(
                  context: context,
                  type: type,
                );
              },
            );

            return BottomBarWidget(
              index: store.index,
              onExit: context.exit,
              onTap: ({required context, required index}) async {
                if (index == BottomBarConstant.transaction.position) {
                  return await transactionBottomSheetFactoryWidget(
                    context: context,
                    type: QuickActionsConstant.output.name,
                  );
                }

                store.switchChild(index);
                shell.switchChild(index);
              },
            );
          },
        ),
      ),
    );
  };
}
