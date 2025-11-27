import 'package:duck_router/duck_router.dart';

import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/images/presentation/screens/images_screen.dart';

final class ImagesLocation extends Location {
  @override
  String get path => RoutesConstant.images.path;

  @override
  LocationPageBuilder get pageBuilder =>
      (_) => BottomSheetPage(
        builder: (_) => ImagesScreen(onCameraTap: () {}, onGalleryTap: () {}),
      );
}
