const _path = 'lib/modules/core/presentation/assets';

enum AssetsConstant {
  logo(source: '$_path/images/logo.webp');

  final String source;

  const AssetsConstant({required this.source});
}
