import 'dart:io';

import 'package:trocado/modules/core/domain/constant/images_constant.dart';

abstract interface class IImageDatasource {
  Future<File?> call(ImagesConstant type);
}
