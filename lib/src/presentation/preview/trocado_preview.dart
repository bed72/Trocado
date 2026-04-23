import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:trocado/src/presentation/widgets/preview/material_preview_widget.dart';

Widget trocadoPreviewWrapper(Widget child) =>
    _LocaleReadyWidget(child: MaterialPreviewWidget(child: child));

final class TrocadoPreview extends Preview {
  const TrocadoPreview({super.name, super.size, super.group, super.brightness})
    : super(wrapper: trocadoPreviewWrapper);
}

class _LocaleReadyWidget extends StatefulWidget {
  final Widget child;

  const _LocaleReadyWidget({required this.child});

  @override
  State<_LocaleReadyWidget> createState() => _LocaleReadyWidgetState();
}

class _LocaleReadyWidgetState extends State<_LocaleReadyWidget> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR').then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? widget.child : const SizedBox.shrink();
}
