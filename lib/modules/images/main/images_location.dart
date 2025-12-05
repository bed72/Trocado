import 'package:duck_router/duck_router.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/images/presentation/screens/images_screen.dart';

final class ImagesLocation extends Location {
  @override
  String get path => RoutesConstant.images.path;

  @override
  LocationPageBuilder get pageBuilder => (context) {
    final store = context.get<ImageStore>();

    return BottomSheetPage(
      builder: (_) => SignalBuilder(
        builder: (_, _) => ImagesScreen(
          onCameraTap: () {
            store.type.value = ImagesConstant.camera;
            context.pop();
          },
          onGalleryTap: () {
            store.type.value = ImagesConstant.gallery;
            context.pop();
          },
        ),
      ),
    );
  };
}
