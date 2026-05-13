import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

class FormSubmitButtonWidget extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const FormSubmitButtonWidget({
    super.key,
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ButtonWidget.elevated(
      label: label,
      isLoading: isLoading,
      onTap: isLoading ? null : onTap,
    ),
  );
}
