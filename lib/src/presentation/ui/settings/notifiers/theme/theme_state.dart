import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/enums/theme/theme_mode_enum.dart';

final class ThemeState extends Equatable {
  final ThemeModeEnum mode;

  const ThemeState({this.mode = .system});

  ThemeState copyWith({ThemeModeEnum? mode}) =>
      ThemeState(mode: mode ?? this.mode);

  @override
  List<Object?> get props => [mode];
}
