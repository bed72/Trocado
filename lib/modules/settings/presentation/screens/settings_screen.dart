import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/settings/presentation/dtos/settings_dto.dart';

import 'package:trocado/modules/settings/presentation/widgets/profile_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/finances_session_widget.dart';
import 'package:trocado/modules/settings/presentation/widgets/sessions/application_settings_session_widget.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsDto dto;

  const SettingsScreen({super.key, required this.dto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Configurações'),
      body: SafeArea(
        child: Padding(
          padding: const .symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 32.0),
                    Observer(
                      builder: (context) {
                        final store = context.get<UserStore>()..find();

                        return ProfileWidget(
                          onEdit: dto.onUserTap,
                          name: store.user.name ?? '',
                          resource:
                              store.user.image ??
                              'https://avatars.githubusercontent.com/u/30250307?s=96&v=4',
                        );
                      },
                    ),
                    FinancesSessionWidget(dto: dto),
                    ApplicationSettingsSessionWidget(dto: dto),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ButtonWidget.ghost(
                  child: Text(
                    'Deletar dados',
                    style: TextStyle(color: context.colors.error),
                  ),
                  onTap: () {
                    // TODO implementar
                  },
                ),
              ),
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
