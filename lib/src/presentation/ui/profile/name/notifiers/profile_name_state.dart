import 'package:equatable/equatable.dart';

enum ProfileNameStatus { initial, loading, success, failure }

final class ProfileNameState extends Equatable {
  final String name;
  final String message;
  final String? nameFailure;
  final ProfileNameStatus status;

  const ProfileNameState({
    this.name = '',
    this.message = '',
    this.nameFailure,
    this.status = .initial,
  });

  ProfileNameState copyWith({
    String? name,
    String? message,
    String? nameFailure,
    ProfileNameStatus? status,
    bool clearNameFailure = false,
  }) => ProfileNameState(
    name: name ?? this.name,
    status: status ?? this.status,
    message: message ?? this.message,
    nameFailure: clearNameFailure ? null : nameFailure ?? this.nameFailure,
  );

  @override
  List<Object?> get props => [name, message, nameFailure, status];
}
