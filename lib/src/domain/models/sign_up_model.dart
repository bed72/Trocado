import 'package:equatable/equatable.dart';

import 'package:trocado/src/domain/models/user_model.dart';

final class SignUpModel extends Equatable {
  final String access;
  final String refresh;
  final UserModel user;

  const SignUpModel({
    required this.user,
    required this.access,
    required this.refresh,
  });

  SignUpModel copyWith({String? access, String? refresh, UserModel? user}) =>
      SignUpModel(
        user: user ?? this.user,
        access: access ?? this.access,
        refresh: refresh ?? this.refresh,
      );

  @override
  List<Object> get props => [access, refresh, user];
}
