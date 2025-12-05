import 'package:duck_router/duck_router.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/images/presentation/screens/images_screen.dart';

final class ImagesLocation extends Location {
  @override
  String get path => RoutesConstant.images.path;

  @override
  LocationPageBuilder get pageBuilder => (context) {
    final store = context.get<ImageStore>();

    return BottomSheetPage(
      builder: (_) => Observer(
        builder: (_) => ImagesScreen(
          onCameraTap: () {
            store.toggle(.camera);
            context.pop();
          },
          onGalleryTap: () {
            store.toggle(.gallery);
            context.pop();
          },
        ),
      ),
    );
  };
}
