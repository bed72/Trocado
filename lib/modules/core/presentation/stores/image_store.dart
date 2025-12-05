import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';
import 'package:trocado/modules/core/domain/constant/storage_contant.dart';

import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class ImageStore {
  final IImageRepository _imageRepository;
  final IStorageRepository _storageRepository;

  final type = Signal<ImagesConstant?>(null);
  late final resource = Resource(_toggle, source: type);

  ImageStore({
    required IImageRepository imageRepository,
    required IStorageRepository storageRepository,
  }) : _imageRepository = imageRepository,
       _storageRepository = storageRepository;

  Future<String?> _toggle() async {
    if (type.value == null) return null;

    final file = await _imageRepository(type: type.value!);

    if (file == null) return null;

    await _save(file.path);

    return file.path;
  }

  Future<void> _save(String path) async {
    await _storageRepository.save(
      value: path,
      key: StorageConstant.userImage.key,
    );
  }
}
