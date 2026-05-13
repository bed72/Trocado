import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/form_submit_button_widget.dart';
import 'package:trocado/src/presentation/widgets/circular_progress_indicator_widget.dart';

import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_state.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_intent.dart';
import 'package:trocado/src/presentation/ui/profile/name/notifiers/profile_name_notifier.dart';

class ProfileNameScreen extends StatelessWidget {
  final VoidCallback onSuccess;

  const ProfileNameScreen({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Consumer(
      builder: (_, ref, _) {
        ref.listen(profileNameProvider, (previous, next) {
          final previousStatus = previous?.value?.status;
          final nextStatus = next.value?.status;

          if (nextStatus == .failure && previousStatus != .failure) {
            showToastWidget(
              context: context,
              title: 'Opps',
              type: .failure,
              description: next.value?.message ?? '',
            );
          }

          if (nextStatus == .success && previousStatus != .success) {
            onSuccess();
          }
        });

        return switch (ref.watch(profileNameProvider)) {
          AsyncData(:final value) => _buildBody(
            state: value,
            notifier: ref.read(profileNameProvider.notifier),
          ),
          AsyncError(:final error) => _buildError(
            failure: error is Failure ? error : const UnknownFailure(),
            onRetry: () => ref.invalidate(profileNameProvider),
          ),
          _ => const Center(child: CircularProgressIndicatorWidget()),
        };
      },
    ),
  );

  CustomScrollView _buildBody({
    required ProfileNameState state,
    required ProfileNameNotifier notifier,
  }) => CustomScrollView(
    slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const .all(16.0),
          child: Column(
            spacing: 24.0,
            crossAxisAlignment: .start,
            children: [
              const ScreenHeaderWidget(
                title: 'Nome',
                description: 'Atualize o seu nome de exibição.',
              ),
              TextFieldWidget(
                hint: 'Nome',
                label: 'Nome',
                inputAction: .done,
                initialValue: state.name,
                failure: state.nameFailure,
                onChanged: (value) => notifier.dispatch(NameChanged(value)),
              ),
              const Spacer(),
              FormSubmitButtonWidget(
                label: 'Atualizar',
                isLoading: state.status == .loading,
                onTap: () {
                  hideKeyboard();
                  notifier.dispatch(const SubmitPressed());
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildError({
    required Failure failure,
    required VoidCallback onRetry,
  }) => Center(
    child: Column(
      spacing: 16.0,
      mainAxisSize: .min,
      children: [
        Text(failure.message, textAlign: .center),
        ButtonWidget.outlined(label: 'Tentar novamente', onTap: onRetry),
      ],
    ),
  );
}
