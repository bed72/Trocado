import 'package:equatable/equatable.dart';

enum ProfileDetailsStatus { initial, loading, success, failure }

final class ProfileDetailsState extends Equatable {
  final String message;
  final ProfileDetailsStatus status;

  const ProfileDetailsState({this.message = '', this.status = .initial});

  ProfileDetailsState copyWith({
    String? message,
    ProfileDetailsStatus? status,
  }) => ProfileDetailsState(
    status: status ?? this.status,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [status, message];
}
