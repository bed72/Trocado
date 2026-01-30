const _path = 'lib/modules/core/presentation/assets';

enum AssetsConstant {
  logo(source: '$_path/images/logo.webp'),
  scope(source: '$_path/images/scope.webp'),
  iceberg(source: '$_path/images/iceberg.webp'),
  breaking(source: '$_path/images/breaking.webp');

  final String source;

  const AssetsConstant({required this.source});
}
