const _path = 'lib/src/presentation/assets';

enum AssetsConstant {
  logo(source: '$_path/images/logo.webp'),
  iceberg(source: '$_path/images/iceberg.webp'),
  breaking(source: '$_path/images/breaking.webp');

  final String source;

  const AssetsConstant({required this.source});
}
