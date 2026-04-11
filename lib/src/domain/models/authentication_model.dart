import 'package:equatable/equatable.dart';

final class AuthenticationModel extends Equatable {
  final String access;
  final String refresh;

  const AuthenticationModel({required this.access, required this.refresh});

  @override
  List<Object?> get props => [access, refresh];

  AuthenticationModel copyWith({String? access, String? refresh}) =>
      AuthenticationModel(
        access: access ?? this.access,
        refresh: refresh ?? this.refresh,
      );
}
