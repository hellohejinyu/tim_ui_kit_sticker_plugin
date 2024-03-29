import 'dart:ui';

import 'package:delayed_display/delayed_display.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:tencent_im_base/i18n/i18n_utils.dart';
import 'package:tim_ui_kit_sticker_plugin/utils/tim_ui_kit_sticker_data.dart';

class StickerPanel extends StatefulWidget {
  final void Function() sendTextMsg;
  final void Function(int index, String data) sendFaceMsg;
  final void Function(int unicode) addText;
  final void Function() deleteText;
  final List<CustomStickerPackage> customStickerPackageList;
  final Widget? emptyPlaceHolder;
  final void Function(BuildContext context, LayerLink layerLink,
      int selectedPackageIdx, CustomSticker selectedSticker)? onLongTap;
  final int crossAxisCount;
  final Color? backgroundColor;
  final Color? lightPrimaryColor;
  final EdgeInsetsGeometry? panelPadding;

  const StickerPanel({
    Key? key,
    required this.sendTextMsg,
    required this.sendFaceMsg,
    required this.deleteText,
    required this.addText,
    required this.customStickerPackageList,
    this.emptyPlaceHolder,
    this.onLongTap,
    this.backgroundColor = const Color(0xFFEDEDED),
    this.lightPrimaryColor = const Color(0xFF3371CD),
    this.crossAxisCount = 8,
    this.panelPadding,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<StickerPanel> {
  int selectedIdx = 0;
  late List<int> textEmojiIndexList;

  void filterTextEmojiIndexList() {
    List<int> textEmojiList = [];
    widget.customStickerPackageList
        .asMap()
        .keys
        .forEach((customStickerPackageIndex) {
      if (!widget.customStickerPackageList[customStickerPackageIndex]
          .isCustomSticker) {
        textEmojiList.add(customStickerPackageIndex);
      }
    });
    setState(() {
      textEmojiIndexList = textEmojiList;
    });
  }

  List<Widget> _buildEmojiListWidget(
    List<CustomStickerPackage> customStickerList,
  ) {
    List<Widget> list = [];
    for (var index = 0; index < (customStickerList.length); index++) {
      final customEmojiFace = customStickerList[index];

      list.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedIdx = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            height: 40,
            margin: const EdgeInsets.only(
              right: 4,
            ),
            decoration: BoxDecoration(
              color: selectedIdx == index
                  ? widget.lightPrimaryColor
                  : widget.backgroundColor,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            child: Center(
              child: customEmojiFace.isCustomSticker
                  ? CustomEmojiItem(
                      sticker: customEmojiFace.menuItem,
                      baseUrl: customEmojiFace.baseUrl,
                    )
                  : EmojiItem(
                      name: customEmojiFace.menuItem.name,
                      unicode: customEmojiFace.menuItem.unicode!,
                    ),
            ),
          ),
        ),
      );
    }
    return list;
  }

  Widget _buildEmojiPanel(List<int> textEmojiIndexList,
      List<CustomStickerPackage> customStickerList) {
    if (customStickerList.isEmpty) return Container();
    if (customStickerList[selectedIdx].stickerList.isEmpty) {
      return widget.emptyPlaceHolder ??
          Center(
            child: Text(
              TIM_t("暂无表情"),
              style: const TextStyle(
                color: Colors.black12,
                fontSize: 24,
              ),
            ),
          );
    }
    if (textEmojiIndexList.contains(selectedIdx)) {
      return GridView(
        key: ValueKey(selectedIdx),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          childAspectRatio: 1,
        ),
        children: [
          ...customStickerList[selectedIdx].stickerList.map(
            (item) {
              LayerLink layerLink = LayerLink();
              return GestureDetector(
                onTap: () {
                  widget.addText(item.unicode!);
                },
                onLongPressStart: (LongPressStartDetails details) {
                  if (widget.onLongTap != null) {
                    widget.onLongTap!(context, layerLink, selectedIdx, item);
                  }
                },
                child: CompositedTransformTarget(
                  link: layerLink,
                  child: Center(
                    child: EmojiItem(
                      name: item.name,
                      unicode: item.unicode!,
                    ),
                  ),
                ),
              );
            },
          ).toList()
        ],
      );
    }

    return GridView(
      key: ValueKey(selectedIdx),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
      children: customStickerList[selectedIdx].stickerList.map(
        (item) {
          LayerLink layerLink = LayerLink();
          return GestureDetector(
            onTap: () {
              widget.sendFaceMsg(
                  item.index,
                  customStickerList[selectedIdx].baseUrl == null
                      ? item.url!
                      : '${customStickerList[selectedIdx].baseUrl!}/${item.name}');
            },
            onLongPressStart: (LongPressStartDetails details) {
              if (widget.onLongTap != null) {
                widget.onLongTap!(context, layerLink, selectedIdx, item);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CompositedTransformTarget(
                link: layerLink,
                child: CustomEmojiItem(
                  isBigImage: true,
                  baseUrl: customStickerList[selectedIdx].baseUrl,
                  sticker: item,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildBottomPanel(
    List<int> textEmojiIndexList,
    List<CustomStickerPackage> customStickerList,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildEmojiListWidget(customStickerList),
              ),
            ),
          ),
        ),
        if (textEmojiIndexList.contains(selectedIdx))
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              widget.deleteText();
            },
            child: const Icon(
              Icons.backspace_rounded,
              color: Colors.black,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    filterTextEmojiIndexList();
    return DelayedDisplay(
      delay: const Duration(milliseconds: 100),
      fadingDuration: const Duration(milliseconds: 300),
      slidingBeginOffset: const Offset(0.0, 0.05),
      child: GestureDetector(
        onTap: () {
          /// 阻止点击空白区域导致表情 Panel 被关闭
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _buildEmojiPanel(
                textEmojiIndexList,
                widget.customStickerPackageList,
              ),
            ),
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBottomPanel(
                  textEmojiIndexList,
                  widget.customStickerPackageList,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}

class EmojiItem extends StatelessWidget {
  const EmojiItem({Key? key, required this.name, required this.unicode})
      : super(key: key);
  final String name;
  final int unicode;
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 26,
      ),
      child: Text(
        String.fromCharCode(unicode),
      ),
    );
  }
}

class CustomEmojiItem extends StatefulWidget {
  const CustomEmojiItem({
    Key? key,
    required this.sticker,
    this.baseUrl,
    this.isBigImage = false,
  }) : super(key: key);

  final CustomSticker sticker;
  final String? baseUrl;
  final bool? isBigImage;

  @override
  State<StatefulWidget> createState() => _CustomEmojiItemState();
}

class _CustomEmojiItemState extends State<CustomEmojiItem> {
  /// gif图片首帧
  ImageInfo? _imageInfo;

  @override
  initState() {
    super.initState();
  }

  bool isFromNetwork() {
    if (widget.baseUrl == null) {
      return widget.sticker.url!.startsWith('http');
    }
    return widget.baseUrl!.startsWith('http');
  }

  String getUrl() {
    return widget.baseUrl == null
        ? widget.sticker.url!
        : '${widget.baseUrl!}/${widget.sticker.name}';
  }

  bool isAnimated() {
    String url = getUrl();
    return url.endsWith("gif") || url.endsWith("webp") || url.endsWith("apng");
  }

  double get size => widget.isBigImage! ? 60 : 30;

  void _buildFirstFrameFromNetworkImg(String url) async {
    final cache = await DefaultCacheManager().getSingleFile(url);
    final data = await cache.readAsBytes();
    _getFirstFrame(data);
  }

  void _buildFirstFrameFromLocalImg(ImageProvider image) async {
    dynamic data;
    if (image is AssetImage) {
      AssetBundleImageKey key =
          await image.obtainKey(const ImageConfiguration());
      data = await key.bundle.load(key.name);
    } else if (image is FileImage) {
      data = await image.file.readAsBytes();
    } else if (image is MemoryImage) {
      data = image.bytes;
    }
    _getFirstFrame(data);
  }

  void _getFirstFrame(dynamic data) async {
    var codec = await PaintingBinding.instance
        .instantiateImageCodecWithSize(data.buffer.asUint8List());
    FrameInfo? frameInfo = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _imageInfo = ImageInfo(image: frameInfo.image);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String url = getUrl();
    bool isImgFromNetwork = isFromNetwork();
    bool isImgAnimated = isAnimated();
    Widget? img;
    if (isImgAnimated && isImgFromNetwork) {
      _buildFirstFrameFromNetworkImg(url);
    }
    if (isImgAnimated && !isImgFromNetwork) {
      _buildFirstFrameFromLocalImg(
        Image.asset(
          url,
          height: size,
          width: size,
        ).image,
      );
    }
    if (!isImgAnimated && isImgFromNetwork) {
      img = ExtendedImage.network(
        url,
        height: size,
        width: size,
      );
    }
    if (!isImgAnimated && !isImgFromNetwork) {
      img = Image.asset(
        url,
        height: size,
        width: size,
      );
    }
    return Container(
      child: isImgAnimated
          ? RawImage(
              image: _imageInfo?.image,
              width: size,
              height: size,
            )
          : img,
    );
  }
}
