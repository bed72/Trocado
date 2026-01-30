import 'dart:async';

import 'package:flutter/material.dart';

void addPostFrameCallback(FutureOr<void> Function() callback) {
  WidgetsBinding.instance.addPostFrameCallback((_) async => callback());
}
