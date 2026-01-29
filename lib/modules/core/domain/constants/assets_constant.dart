const _path = 'lib/modules/core/presentation/assets';

enum AssetsConstant {
  bag(source: '$_path/images/bag.webp'),
  logo(source: '$_path/images/logo.webp'),
  money(source: '$_path/images/money.webp'),
  empty(source: '$_path/images/empty.webp');

  final String source;

  const AssetsConstant({required this.source});
}
