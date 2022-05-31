import 'dart:async';
import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:bonfire/map/map_paint.dart';
import 'package:bonfire/util/assets_loader.dart';
import 'package:bonfire/util/controlled_update_animation.dart';
import 'package:flutter/widgets.dart';

class Tile extends GameComponent with UseAssetsLoader {
  final String? type;
  final Map<String, dynamic>? properties;
  late Vector2 _positionText;
  Paint? _paintText;
  TextPaint? _textPaintConfig;
  String id = '';
  Sprite? _sprite;
  ControlledUpdateAnimation? _animation;
  Color? color;

  Tile({
    required String spritePath,
    required Vector2 position,
    required Vector2 size,
    this.type,
    this.properties,
    this.color,
    double offsetX = 0,
    double offsetY = 0,
  }) {
    generateRectWithBleedingPixel(
      position,
      size,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    if (spritePath.isNotEmpty) {
      loader?.add(
        AssetToLoad(Sprite.load(spritePath), (value) => this._sprite = value),
      );
    }

    _positionText = position;
  }

  Tile.fromSprite({
    required Sprite? sprite,
    required Vector2 position,
    required Vector2 size,
    this.type,
    this.properties,
    double offsetX = 0,
    double offsetY = 0,
    this.color,
  }) {
    id = '${position.x}/${position.y}';
    this._sprite = sprite;
    generateRectWithBleedingPixel(
      position,
      size,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    _positionText = position;
  }

  Tile.fromAnimation({
    required ControlledUpdateAnimation animation,
    required Vector2 position,
    required Vector2 size,
    this.type,
    this.properties,
    double offsetX = 0,
    double offsetY = 0,
  }) {
    id = '${position.x}/${position.y}';
    this._animation = animation;
    generateRectWithBleedingPixel(
      position,
      size,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    _positionText = position;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _animation?.render(
      canvas,
      position: position,
      size: size,
      overridePaint: MapPaint.instance.paint,
    );
    _sprite?.render(
      canvas,
      position: position,
      size: size,
      overridePaint: MapPaint.instance.paint,
    );
    if (_animation == null && _sprite == null && color != null) {
      canvas.drawRect(toRect(), MapPaint.instance.paint..color = color!);
    }
  }

  @override
  void renderDebugMode(Canvas canvas) {
    _drawGrid(canvas);
  }

  void _drawGrid(Canvas canvas) {
    if (_paintText == null) {
      _paintText = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
    }
    canvas.drawRect(
      toRect(),
      _paintText!
        ..color =
            gameRef.constructionModeColor ?? Color(0xFF00BCD4).withOpacity(0.5),
    );
    if (_positionText.x % 2 == 0) {
      if (_textPaintConfig == null) {
        _textPaintConfig = TextPaint(
          style: TextStyle(
            fontSize: width / 3,
            color: gameRef.constructionModeColor ??
                Color(0xFF00BCD4).withOpacity(0.5),
          ),
        );
      }
      _textPaintConfig?.render(
        canvas,
        '${_positionText.x.toInt()}:${_positionText.y.toInt()}',
        Vector2(position.x + 2, position.y + 2),
      );
    }
  }

  void generateRectWithBleedingPixel(
    Vector2 position,
    Vector2 size, {
    double offsetX = 0,
    double offsetY = 0,
  }) {
    double bleendingPixel = max(size.x, size.y) * 0.05;
    if (bleendingPixel > 2) {
      bleendingPixel = 2;
    }
    this.position = Vector2(
      (position.x * size.x) -
          (position.x % 2 == 0 ? (bleendingPixel / 2) : 0) +
          offsetX,
      (position.y * size.y) -
          (position.y % 2 == 0 ? (bleendingPixel / 2) : 0) +
          offsetY,
    );
    this.size = Vector2(
      size.x + (position.x % 2 == 0 ? bleendingPixel : 0),
      size.y + (position.y % 2 == 0 ? bleendingPixel : 0),
    );
  }

  @override
  // ignore: must_call_super
  void update(double dt) {
    _animation?.update(dt);

    /// not used super.update(dt); to avoid consulting unnecessary computational resources
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _animation?.onLoad();
  }

  bool get containAnimation => _animation != null;
}
