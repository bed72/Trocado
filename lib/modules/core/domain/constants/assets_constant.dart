const _path = 'lib/modules/core/presentation/assets';

enum AssetsConstant {
  logo(source: '$_path/images/logo.webp'),
  empty(source: '$_path/images/empty.webp');

  final String source;

  const AssetsConstant({required this.source});
}
