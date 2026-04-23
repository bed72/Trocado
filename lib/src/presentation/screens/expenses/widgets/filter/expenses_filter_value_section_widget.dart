import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/formatters/currency_field_formatter.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

class ExpensesFilterValueSectionWidget extends StatefulWidget {
  final int? minValue;
  final int? maxValue;
  final ValueChanged<int?> onMinChanged;
  final ValueChanged<int?> onMaxChanged;

  const ExpensesFilterValueSectionWidget({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  @override
  State<ExpensesFilterValueSectionWidget> createState() =>
      _ExpensesFilterValueSectionWidgetState();
}

class _ExpensesFilterValueSectionWidgetState
    extends State<ExpensesFilterValueSectionWidget> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: CurrencyFieldFormatter.formatCentavos(widget.minValue),
    );
    _maxController = TextEditingController(
      text: CurrencyFieldFormatter.formatCentavos(widget.maxValue),
    );
  }

  @override
  void didUpdateWidget(ExpensesFilterValueSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_minController, oldWidget.minValue, widget.minValue);
    _sync(_maxController, oldWidget.maxValue, widget.maxValue);
  }

  void _sync(TextEditingController controller, int? oldValue, int? newValue) {
    if (oldValue == newValue) return;

    final formatted = CurrencyFieldFormatter.formatCentavos(newValue);
    if (controller.text != formatted) controller.text = formatted;
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    spacing: 12.0,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Valor',
        style: context.typography.titleMedium?.copyWith(fontWeight: .w600),
      ),
      Row(
        spacing: 12.0,
        children: [
          Expanded(
            child: TextFieldWidget(
              label: 'Mínimo',
              hint: 'R\$ 0,00',
              keyboardType: .number,
              controller: _minController,
              inputFormatters: [CurrencyFieldFormatter()],
              onChanged: (text) => widget.onMinChanged(
                CurrencyFieldFormatter.parseCentavos(text),
              ),
            ),
          ),
          Expanded(
            child: TextFieldWidget(
              label: 'Máximo',
              hint: 'R\$ 0,00',
              keyboardType: .number,
              controller: _maxController,
              inputFormatters: [CurrencyFieldFormatter()],
              onChanged: (text) => widget.onMaxChanged(
                CurrencyFieldFormatter.parseCentavos(text),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
