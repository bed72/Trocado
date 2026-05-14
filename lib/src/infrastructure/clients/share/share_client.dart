import 'package:share_plus/share_plus.dart';

abstract interface class IShareClient {
  Future<void> shareText(String text);
}

final class ShareClient implements IShareClient {
  @override
  Future<void> shareText(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}
