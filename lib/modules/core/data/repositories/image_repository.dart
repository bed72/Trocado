import 'dart:io';

import 'package:trocado/modules/core/data/datasources/interface_image_datasource.dart';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';
import 'package:trocado/modules/core/domain/repositories/interface_image_repository.dart';

final class ImageRepository implements IImageRepository {
  final IImageDatasource _datasource;

  ImageRepository({required IImageDatasource datasource})
    : _datasource = datasource;

  @override
  Future<File?> call({required ImagesConstant type}) async =>
      _datasource.call(type);
}
