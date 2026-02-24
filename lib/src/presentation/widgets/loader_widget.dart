import 'package:flutter_rearch/flutter_rearch.dart';
import 'package:rearch/rearch.dart';
import 'package:flutter/material.dart';

typedef RefreshableAsync<T> = (AsyncValue<T>, void Function());

class LoaderWidget<T> extends StatelessWidget {
  final Widget success;
  final Widget loading;
  final Widget Function(List<AsyncError<T>>) failure;
  final RefreshableAsync<T> Function(CapsuleHandle) capsule;

  const LoaderWidget({
    super.key,
    required this.success,
    required this.loading,
    required this.failure,
    required this.capsule,
  });

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (value, _) = use(capsule);

        return [value].toWarmUpWidget(
          child: success,
          loading: loading,
          errorBuilder: failure,
        );
      },
    );
  }
}
