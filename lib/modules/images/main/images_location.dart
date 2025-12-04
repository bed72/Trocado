import 'dart:io';

import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/images/presentation/screens/images_screen.dart';

final class ImagesLocation extends Location {
  @override
  String get path => RoutesConstant.images.path;

  @override
  LocationPageBuilder get pageBuilder => (context) {
    final image = context.get<ImageCommand>();

    return BottomSheetPage(
      builder: (_) => ConsumerBuilder<ImagesConstant, File?>(
        command: image.command,
        data: (_, _, _) => ImagesScreen(
          onCameraTap: () async {
            image.command(ImagesConstant.camera);
            context.pop();
          },
          onGalleryTap: () async {
            image.command(ImagesConstant.gallery);
            context.pop();
          },
        ),
      ),
    );
  };
}
