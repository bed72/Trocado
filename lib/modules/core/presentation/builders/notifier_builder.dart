import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ConsumersBuilder<A, B> extends StatelessWidget {
  final Widget Function(BuildContext context, A a, B b) builder;

  const ConsumersBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer2<A, B>(
      builder: (context, a, b, _) => builder(context, a, b),
    );
  }
}

class ConsumerManyBuilder<A, B, C> extends StatelessWidget {
  final Widget Function(BuildContext context, A a, B b, C c) builder;

  const ConsumerManyBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer3<A, B, C>(
      builder: (context, a, b, c, _) => builder(context, a, b, c),
    );
  }
}

class ConsumerBuilder<T extends ChangeNotifier> extends StatelessWidget {
  final T notifier;

  final Widget Function(BuildContext context, T notifier) builder;

  const ConsumerBuilder({
    super.key,
    required this.builder,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: notifier,
      child: Consumer<T>(
        builder: (context, notifier, _) => builder(context, notifier),
      ),
    );
  }
}

class SelectorBuilder<T extends ChangeNotifier, S> extends StatelessWidget {
  final T notifier;
  final S Function(T notifier) selector;

  final Widget Function(BuildContext context, T notifier, S selected) builder;

  const SelectorBuilder({
    super.key,
    required this.notifier,
    required this.selector,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: notifier,
      child: Selector<T, S>(
        selector: (_, n) => selector(n),
        builder: (context, selected, _) => builder(context, notifier, selected),
      ),
    );
  }
}
