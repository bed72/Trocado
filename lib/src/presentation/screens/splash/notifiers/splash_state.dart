import 'package:equatable/equatable.dart';

enum SplashStatus { loading, authenticated, unauthenticated }

final class SplashState extends Equatable {
  final SplashStatus status;

  const SplashState({this.status = .loading});

  SplashState copyWith({SplashStatus? status}) =>
      SplashState(status: status ?? this.status);

  @override
  List<Object?> get props => [status];
}
