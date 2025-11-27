import 'dart:io';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';
import 'package:trocado/modules/core/domain/constant/storage_contant.dart';

import 'package:trocado/modules/core/presentation/notifiers/notifier.dart';

import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class ImageNotifier extends Notifier<File?> {
  final IImageRepository _imageRepository;
  final IStorageRepository _storageRepository;

  ImageNotifier({
    required IImageRepository imageRepository,
    required IStorageRepository storageRepository,
  }) : _imageRepository = imageRepository,
       _storageRepository = storageRepository,
       super(null);

  bool get hasImage => state != null;

  Future<void> call({required ImagesConstant type}) async {
    final file = await _imageRepository(type: type);

    if (file == null) return;

    state = file;
    await _save(file.path);
  }

  Future<void> ensureInitialized() async {
    final data = await _storageRepository.get(key: StorageConstant.image.key);
    if (data == null || data.isEmpty) return;

    final file = File(data);
    if (!await file.exists()) return;

    state = file;
  }

  Future<void> _save(String path) async {
    await _storageRepository.save(key: StorageConstant.image.key, value: path);
  }
}
