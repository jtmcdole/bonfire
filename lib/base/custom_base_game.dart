import 'package:bonfire/base/game_component.dart';
import 'package:bonfire/util/camera/camera.dart';
import 'package:bonfire/util/mixins/pointer_detector.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart' hide Camera;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ordered_set/comparing.dart';
import 'package:ordered_set/ordered_set.dart';

abstract class CustomBaseGame extends Game with FPSCounter, PointerDetector {
  Camera gameCamera = Camera();

  /// The list of components to be updated and rendered by the base game.
  OrderedSet<Component> components = OrderedSet(Comparing.on((c) {
    return c.priority;
  }));

  /// Components added by the [addLater] method
  final List<Component> _addLater = [];

  Iterable<PointerDetectorHandler> get _gesturesComponents {
    return components
        .where((c) => _hasGesture(c))
        .cast<PointerDetectorHandler>();
  }

  void onPointerCancel(PointerCancelEvent event) {
    _gesturesComponents.forEach((c) => c.handlerPointerCancel(event));
  }

  void onPointerUp(PointerUpEvent event) {
    for (final c in _gesturesComponents) {
      c.handlerPointerUp(event);
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    for (final c in _gesturesComponents) {
      c.handlerPointerMove(event);
    }
  }

  void onPointerDown(PointerDownEvent event) {
    for (final c in _gesturesComponents) {
      c.handlerPointerDown(event);
    }
  }

  /// This method is called for every component added, both via [add] and [addLater] methods.
  ///
  /// You can use this to setup your mixins, pre-calculate stuff on every component, or anything you desire.
  /// By default, this calls the first time resize for every component, so don't forget to call super.preAdd when overriding.
  @mustCallSuper
  Future<void> preAdd(Component c) async {
    if (debugMode && c is PositionComponent) {
      c.debugMode = true;
    }

    if (c is HasGameRef) {
      (c as HasGameRef).gameRef = this;
    }

    // first time resize
    if (size != null) {
      c.onGameResize(size);
    }

    final loadFuture = c.onLoad();

    if (loadFuture != null) {
      await loadFuture;
    }

    if (c is PositionComponent) {
      c.children.forEach(preAdd);
    }
  }

  /// Adds a new component to the components list.
  ///
  /// Also calls [preAdd], witch in turn sets the current size on the component (because the resize hook won't be called until a new resize happens).
  Future<void> add(Component c) async {
    await preAdd(c);
    _addLater.add(c);
  }

  /// This implementation of render basically calls [renderComponent] for every component, making sure the canvas is reset for each one.
  ///
  /// You can override it further to add more custom behaviour.
  /// Beware of however you are rendering components if not using this; you must be careful to save and restore the canvas to avoid components messing up with each other.
  @override
  void render(Canvas canvas) {
    canvas.save();

    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(gameCamera.zoom);
    canvas.translate(-gameCamera.position.dx, -gameCamera.position.dy);

    components.forEach((comp) => renderComponent(canvas, comp));
    canvas.restore();
  }

  /// This renders a single component obeying BaseGame rules.
  ///
  /// It translates the camera unless hud, call the render method and restore the canvas.
  /// This makes sure the canvas is not messed up by one component and all components render independently.
  void renderComponent(Canvas canvas, Component comp) {
    if (comp is GameComponent) {
      if (!comp.isHud && !comp.isVisibleInCamera()) return;
    }

    canvas.save();

    if (comp.isHud) {
      canvas.translate(gameCamera.position.dx, gameCamera.position.dy);
      canvas.scale(1 / gameCamera.zoom);
      canvas.translate(-size.x / 2, -size.y / 2);
    }

    comp.render(canvas);
    canvas.restore();
  }

  /// This implementation of update updates every component in the list.
  ///
  /// It also actually adds the components that were added by the [addLater] method, and remove those that are marked for destruction via the [Component.destroy] method.
  /// You can override it further to add more custom behaviour.
  @override
  void update(double t) {
    if (_addLater.isNotEmpty) {
      components.addAll(_addLater);
      _addLater.clear();
    }

    components.forEach((c) => c.update(t));
    components.removeWhere((c) => c.shouldRemove);

    gameCamera.update();
  }

  /// This implementation of resize passes the resize call along to every component in the list, enabling each one to make their decisions as how to handle the resize.
  ///
  /// It also updates the [size] field of the class to be used by later added components and other methods.
  /// You can override it further to add more custom behaviour, but you should seriously consider calling the super implementation as well.
  @override
  @mustCallSuper
  void onResize(Vector2 size) {
    gameCamera.gameRef = this;
    super.onResize(size);
    components.forEach((c) => c.onGameResize(size));
  }

  bool debugMode = false;

  /// Returns the current time in seconds with microseconds precision.
  ///
  /// This is compatible with the `dt` value used in the [update] method.
  double currentTime() {
    return DateTime.now().microsecondsSinceEpoch.toDouble() /
        Duration.microsecondsPerSecond;
  }

  bool _hasGesture(Component c) {
    return ((c is GameComponent && c.isVisibleInCamera()) || c.isHud) &&
        (c is PointerDetectorHandler &&
            (c as PointerDetectorHandler).hasGesture());
  }
}