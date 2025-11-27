import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';
import 'package:trocado/modules/core/data/datasources/interface_image_datasource.dart';

final class ImageDatasource implements IImageDatasource {
  final ImagePicker _client;

  ImageDatasource({required ImagePicker client}) : _client = client;

  @override
  Future<File?> call(ImagesConstant type) async {
    try {
      final data = await _client.pickImage(
        source: type == ImagesConstant.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );

      if (data == null) return null;

      return File(data.path);
    } catch (exception) {
      return null;
    }
  }
}
