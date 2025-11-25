import 'package:flutter/material.dart';

@immutable
class CornerRadiusToken extends ThemeExtension<CornerRadiusToken> {
  const CornerRadiusToken({
    required this.cornerRadius100,
    required this.cornerRadius300,
    required this.cornerRadius500,
    required this.cornerRadius700,
    required this.cornerRadiusFull,
  });

  final BorderRadius cornerRadius100;
  final BorderRadius cornerRadius300;
  final BorderRadius cornerRadius500;
  final BorderRadius cornerRadius700;
  final BorderRadius cornerRadiusFull;

  @override
  CornerRadiusToken copyWith({
    BorderRadius? cornerRadius100,
    BorderRadius? cornerRadius300,
    BorderRadius? cornerRadius500,
    BorderRadius? cornerRadius700,
    BorderRadius? cornerRadiusFull,
  }) => CornerRadiusToken(
    cornerRadius100: cornerRadius100 ?? this.cornerRadius100,
    cornerRadius300: cornerRadius300 ?? this.cornerRadius300,
    cornerRadius500: cornerRadius500 ?? this.cornerRadius500,
    cornerRadius700: cornerRadius700 ?? this.cornerRadius700,
    cornerRadiusFull: cornerRadiusFull ?? this.cornerRadiusFull,
  );

  @override
  CornerRadiusToken lerp(ThemeExtension<CornerRadiusToken>? other, double t) =>
      other is! CornerRadiusToken
      ? this
      : CornerRadiusToken(
          cornerRadius100: .lerp(cornerRadius100, other.cornerRadius100, t)!,
          cornerRadius300: .lerp(cornerRadius300, other.cornerRadius300, t)!,
          cornerRadius500: .lerp(cornerRadius500, other.cornerRadius500, t)!,
          cornerRadius700: .lerp(cornerRadius700, other.cornerRadius700, t)!,
          cornerRadiusFull: .lerp(cornerRadiusFull, other.cornerRadiusFull, t)!,
        );
}

const radius = CornerRadiusToken(
  cornerRadius100: .only(
    bottomLeft: Radius.circular(12),
    topLeft: Radius.circular(12),
    topRight: Radius.circular(12),
    bottomRight: Radius.circular(12),
  ),
  cornerRadius300: .only(
    bottomLeft: Radius.circular(20),
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
    bottomRight: Radius.circular(20),
  ),
  cornerRadius500: .only(
    bottomLeft: Radius.circular(28),
    topLeft: Radius.circular(28),
    topRight: Radius.circular(28),
    bottomRight: Radius.circular(28),
  ),
  cornerRadius700: .only(
    bottomLeft: Radius.circular(36),
    topLeft: Radius.circular(36),
    topRight: Radius.circular(36),
    bottomRight: Radius.circular(36),
  ),
  cornerRadiusFull: .only(
    bottomLeft: Radius.circular(500),
    topLeft: Radius.circular(500),
    topRight: Radius.circular(500),
    bottomRight: Radius.circular(500),
  ),
);
