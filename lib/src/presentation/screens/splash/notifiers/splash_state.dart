import 'package:equatable/equatable.dart';

enum SplashStatus { authenticated, unauthenticated }

final class SplashState extends Equatable {
  final SplashStatus? status;

  const SplashState({this.status});

  SplashState copyWith({SplashStatus? status}) =>
      SplashState(status: status ?? this.status);

  @override
  List<Object?> get props => [status];
}
