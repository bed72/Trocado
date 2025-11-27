import 'dart:io';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';

abstract interface class IImageRepository {
  Future<File?> call({required ImagesConstant type});
}
