import 'dart:io';
import 'package:mobx/mobx.dart';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';
import 'package:trocado/modules/core/domain/constant/storage_contant.dart';

import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

part 'image_store.g.dart';

class ImageStore = ImageStoreBase with _$ImageStore;

abstract class ImageStoreBase with Store {
  final IImageRepository imageRepository;
  final IStorageRepository storageRepository;

  @observable
  String? path;

  ImageStoreBase({
    required this.imageRepository,
    required this.storageRepository,
  });

  @action
  Future<void> ensureInitialized() async {
    final data = await storageRepository.get(
      key: StorageConstant.userImage.key,
    );

    if (data == null) return;

    final file = File(data);
    if (await file.exists()) path = file.path;
  }

  @action
  Future<void> toggle(ImagesConstant type) async {
    final file = await imageRepository(type: type);
    if (file == null) return;

    path = file.path;

    await storageRepository.save(
      value: file.path,
      key: StorageConstant.userImage.key,
    );
  }
}
