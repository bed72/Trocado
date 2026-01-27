import 'package:flutter/material.dart';
import 'package:duck_router/duck_router.dart';

DuckPage screenPage(Widget child) => DuckPage(
  transitionDuration: const Duration(milliseconds: 600),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  transitionsBuilder: (context, animation, _, child) {
    final slideIn = Tween<Offset>(
      end: Offset.zero,
      begin: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(parent: animation, curve: Curves.linear));

    return SlideTransition(position: slideIn, child: child);
  },
  child: child,
);
