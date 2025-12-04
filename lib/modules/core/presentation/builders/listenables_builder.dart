import 'package:flutter/widgets.dart';

import 'package:command_it/command_it.dart';

class ConsumerBuilder<TParam, TResult> extends StatelessWidget {
  final Command<TParam, TResult> command;

  final Widget Function(BuildContext context, TResult data, TParam? param)?
  data;
  final Widget Function(
    BuildContext context,
    TResult? lastValue,
    TParam? param,
  )?
  loading;

  final Widget Function(
    BuildContext context,
    Object,
    TResult? lastValue,
    TParam?,
  )?
  failure;

  const ConsumerBuilder({
    super.key,
    required this.command,
    this.data,
    this.loading,
    this.failure,
  });

  @override
  Widget build(BuildContext context) {
    return CommandBuilder<TParam, TResult>(
      command: command,
      onData: data,
      onError: failure,
      whileRunning: loading,
    );
  }
}
