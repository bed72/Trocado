import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/images/presentation/screens/images_screen.dart';

final class ImagesLocation extends Location {
  @override
  String get path => RoutesConstant.images.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(
        builder: (context) => ConsumerBuilder<ImageNotifier>(
          notifier: context.get<ImageNotifier>(),
          builder: (_, image) => ImagesScreen(
            onCameraTap: () async {
              image(type: ImagesConstant.camera).whenComplete(context.pop);
            },
            onGalleryTap: () async {
              image(type: ImagesConstant.gallery).whenComplete(context.pop);
            },
          ),
        ),
      );
}
