import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/data/dtos/user_dto.dart';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_user_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';

part 'user_store.g.dart';

class UserStore = UserStoreBase with _$UserStore;

abstract class UserStoreBase with Store {
  final IUserRepository _userRepository;
  final IImageRepository _imageRepository;

  @observable
  bool isLoading = false;

  @observable
  UserDto user = UserDto.empty();

  UserStoreBase({
    required IUserRepository userRepository,
    required IImageRepository imageRepository,
  }) : _userRepository = userRepository,
       _imageRepository = imageRepository;

  @action
  Future<void> ensureInitialized() => find();

  @action
  Future<void> toggle(ImagesConstant type) async {
    isLoading = true;

    final file = await _imageRepository(type: type);

    if (file == null) {
      isLoading = false;
      return;
    }

    user = user.copyWith(image: file.path);
    isLoading = false;
  }

  @action
  Future<void> find() async {
    isLoading = true;
    final result = await _userRepository.find();

    result.fold((_) => user = UserDto.empty(), (user) => this.user = user);
    isLoading = false;
  }

  @action
  Future<void> insert(UserDto data) async {
    isLoading = true;

    await Future.delayed(Duration(seconds: 4));
    await _userRepository.insert(data: data);

    user = data;
    isLoading = false;
  }

  @action
  Future<void> update(UserDto data) async {
    isLoading = true;
    await _userRepository.update(data: data);

    user = data;
    isLoading = false;
  }

  @action
  Future<void> delete(UserDto data) async {
    isLoading = true;

    await _userRepository.delete(data: data);

    user = UserDto.empty();
    isLoading = false;
  }
}
