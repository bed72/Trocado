import 'package:flutter/material.dart';

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
          child: ListView(
            children: [
              const SizedBox(height: 32.0),
              ProfileWidget(
                name: 'Bed',
                email: 'bed@gmail.com',
                onEdit: dto.onUserTap,
                url:
                    'https://avatars.githubusercontent.com/u/30250307?s=96&v=4',
              ),
              FinancesSessionWidget(dto: dto),
              ApplicationSettingsSessionWidget(dto: dto),
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
