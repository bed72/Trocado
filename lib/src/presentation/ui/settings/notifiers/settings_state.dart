import 'package:equatable/equatable.dart';

enum SettingsStatus { initial, loading, success, failure }

final class SettingsState extends Equatable {
  final String message;
  final SettingsStatus status;

  const SettingsState({
    this.message = '',
    this.status = SettingsStatus.initial,
  });

  SettingsState copyWith({String? message, SettingsStatus? status}) =>
      SettingsState(
        message: message ?? this.message,
        status: status ?? this.status,
      );

  @override
  List<Object> get props => [message, status];
}
