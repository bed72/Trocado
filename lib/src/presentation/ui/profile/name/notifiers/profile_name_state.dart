import 'package:equatable/equatable.dart';

final class ProfileNameState extends Equatable {
  final String name;
  final String? nameFailure;

  const ProfileNameState({this.name = '', this.nameFailure});

  ProfileNameState copyWith({
    String? name,
    String? nameFailure,
    bool clearNameFailure = false,
  }) => ProfileNameState(
    name: name ?? this.name,
    nameFailure: clearNameFailure ? null : nameFailure ?? this.nameFailure,
  );

  @override
  List<Object?> get props => [name, nameFailure];
}
