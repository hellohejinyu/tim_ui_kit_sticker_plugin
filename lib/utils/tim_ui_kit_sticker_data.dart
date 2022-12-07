class CustomStickerPackage {
  const CustomStickerPackage({
    required this.name,
    this.baseUrl,
    required this.stickerList,
    required this.menuItem,
  });

  final String name;
  final String? baseUrl;
  final List<CustomSticker> stickerList;
  final CustomSticker menuItem;

  bool get isCustomSticker => menuItem.unicode == null;
}

class CustomSticker {
  const CustomSticker(
      {required this.name, required this.index, this.url, this.unicode});

  final int? unicode;
  final String name;
  final int index;
  final String? url;
}
