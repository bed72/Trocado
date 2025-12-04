import 'dart:io';

import 'package:command_it/command_it.dart';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';
import 'package:trocado/modules/core/domain/constant/storage_contant.dart';

import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';
import 'package:trocado/modules/core/domain/repositories/interface_storage_repository.dart';

final class ImageCommand {
  final IImageRepository _imageRepository;
  final IStorageRepository _storageRepository;

  late final command = Command.createAsync<ImagesConstant, File?>(
    _call,
    initialValue: null,
  );

  ImageCommand({
    required IImageRepository imageRepository,
    required IStorageRepository storageRepository,
  }) : _imageRepository = imageRepository,
       _storageRepository = storageRepository;

  Future<void> ensureInitialized() async {
    final data = await _storageRepository.get(key: StorageConstant.image.key);
    if (data == null || data.isEmpty) return;

    final file = File(data);
    if (!await file.exists()) return;

    command.value = file;
  }

  Future<void> _save(String path) async {
    await _storageRepository.save(key: StorageConstant.image.key, value: path);
  }

  Future<File?> _call(ImagesConstant type) async {
    final file = await _imageRepository(type: type);

    if (file == null) return null;

    await _save(file.path);

    return file;
  }
}
