import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../utils/Extensions/app_common.dart';

import '../Constants.dart';

enum DeviceSize { mobile, tablet, desktop }

extension LayoutUtils on BoxConstraints {
  /// returns DeviceSize
  DeviceSize get device {
    if (this.maxWidth >= desktopBreakpointGlobal) {
      return DeviceSize.desktop;
    }
    if (this.maxWidth >= tabletBreakpointGlobal) {
      return DeviceSize.tablet;
    }
    return DeviceSize.mobile;
  }
}

extension WidgetExtension on Widget? {
  /// With custom height and width
  /// Validate given widget is not null and returns given value if null.
  Widget validate({Widget value = const SizedBox()}) => this ?? value;



  /// With custom height and width
  SizedBox withSize({double width = 0.0, double height = 0.0}) {
    return SizedBox(height: height, width: width, child: this);
  }

  /// With custom width
  SizedBox withWidth(double width) => SizedBox(width: width, child: this);

  /// With custom height
  SizedBox withHeight(double height) => SizedBox(height: height, child: this);

  /// return padding top
  Padding paddingTop(double top) {
    return Padding(padding: EdgeInsets.only(top: top), child: this);
  }

  /// return padding left
  Padding paddingLeft(double left) {
    return Padding(padding: EdgeInsets.only(left: left), child: this);
  }

  /// return padding right
  Padding paddingRight(double right) {
    return Padding(padding: EdgeInsets.only(right: right), child: this);
  }

  /// return padding bottom
  Padding paddingBottom(double bottom) {
    return Padding(padding: EdgeInsets.only(bottom: bottom), child: this);
  }

  /// return padding all
  Padding paddingAll(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  /// return custom padding from each side
  Padding paddingOnly({
    double top = 0.0,
    double left = 0.0,
    double bottom = 0.0,
    double right = 0.0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(left, top, right, bottom),
      child: this,
    );
  }

  /// return padding symmetric
  Padding paddingSymmetric({double vertical = 0.0, double horizontal = 0.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal),
      child: this,
    );
  }

  /// set visibility
  Widget visible(bool visible, {Widget? defaultWidget}) {
    return visible ? this! : (defaultWidget ?? SizedBox());
  }

  /// add custom corner radius each side
  ClipRRect cornerRadiusWithClipRRectOnly({
    int bottomLeft = 0,
    int bottomRight = 0,
    int topLeft = 0,
    int topRight = 0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(bottomLeft.toDouble()),
        bottomRight: Radius.circular(bottomRight.toDouble()),
        topLeft: Radius.circular(topLeft.toDouble()),
        topRight: Radius.circular(topRight.toDouble()),
      ),
      child: this,
      clipBehavior: Clip.antiAliasWithSaveLayer,
    );
  }

  /// add corner radius
  ClipRRect cornerRadiusWithClipRRect(double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      child: this,
      clipBehavior: Clip.antiAliasWithSaveLayer,
    );
  }

  /// set widget visibility
  @Deprecated('')
  Visibility withVisibility(
      bool visible, {
        Widget? replacement,
        bool maintainAnimation = false,
        bool maintainState = false,
        bool maintainSize = false,
        bool maintainSemantics = false,
        bool maintainInteractivity = false,
      }) {
    return Visibility(
      visible: visible,
      maintainAnimation: maintainAnimation,
      maintainInteractivity: maintainInteractivity,
      maintainSemantics: maintainSemantics,
      maintainSize: maintainSize,
      maintainState: maintainState,
      child: this!,
      replacement: replacement ?? SizedBox(),
    );
  }




  /// add tap to parent widget
  Widget onTap(
      Function? function, {
        BorderRadius? borderRadius,
        Color? splashColor = Colors.transparent,
        Color? hoverColor = Colors.transparent,
        Color? highlightColor = Colors.transparent,
      }) {
    return InkWell(
      onTap: function as void Function()?,
      borderRadius: borderRadius ?? (defaultInkWellRadius != null ? radius(defaultInkWellRadius) : null),
      child: this,
      splashColor: splashColor ?? defaultInkWellSplashColor,
      hoverColor: hoverColor ?? defaultInkWellHoverColor,
      highlightColor: highlightColor ?? defaultInkWellHighlightColor,
    );
  }

  /// add opacity to parent widget
  Widget opacity({
    required double opacity,
    int durationInSecond = 1,
    Duration? duration,
  }) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: duration ?? Duration(milliseconds: 500),
      child: this,
    );
  }

  /// add rotation to parent widget
  Widget rotate({
    required double angle,
    bool transformHitTests = true,
    Offset? origin,
  }) {
    return Transform.rotate(
      origin: origin,
      angle: angle,
      transformHitTests: transformHitTests,
      child: this,
    );
  }

  /// add scaling to parent widget
  Widget scale({
    required double scale,
    Offset? origin,
    AlignmentGeometry? alignment,
    bool transformHitTests = true,
  }) {
    return Transform.scale(
      scale: scale,
      child: this,
      origin: origin,
      alignment: alignment,
      transformHitTests: transformHitTests,
    );
  }

  /// add translate to parent widget
  Widget translate({
    required Offset offset,
    bool transformHitTests = true,
    Key? key,
  }) {
    return Transform.translate(
      offset: offset,
      transformHitTests: transformHitTests,
      child: this,
      key: key,
    );
  }

  /// set parent widget in center
  Widget center({double? heightFactor, double? widthFactor}) {
    return Center(
      heightFactor: heightFactor,
      widthFactor: widthFactor,
      child: this,
    );
  }






  /// Wrap with ShaderMask widget
  Widget withShaderMask(
      List<Color> colors, {
        BlendMode blendMode = BlendMode.srcATop,
      }) {
    return withShaderMaskGradient(
      LinearGradient(colors: colors),
      blendMode: blendMode,
    );
  }

  /// Wrap with ShaderMask widget Gradient
  Widget withShaderMaskGradient(
      Gradient gradient, {
        BlendMode blendMode = BlendMode.srcATop,
      }) {
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      blendMode: blendMode,
      child: this,
    );
  }

  @deprecated
  Widget withScroll({
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    Axis scrollDirection = Axis.vertical,
    ScrollController? controller,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    bool? primary,
    required bool reverse,
  }) {
    return SingleChildScrollView(
      child: this,
      physics: physics,
      padding: padding,
      scrollDirection: scrollDirection,
      controller: controller,
      dragStartBehavior: dragStartBehavior,
      primary: primary,
      reverse: reverse,
    );
  }

  /// add Expanded to parent widget
  Widget expand({flex = 1}) => Expanded(child: this!, flex: flex);

  /// add Flexible to parent widget
  Widget flexible({flex = 1, FlexFit? fit}) {
    return Flexible(child: this!, flex: flex, fit: fit ?? FlexFit.loose);
  }

  /// add FittedBox to parent widget
  Widget fit({BoxFit? fit, AlignmentGeometry? alignment}) {
    return FittedBox(
      child: this,
      fit: fit ?? BoxFit.contain,
      alignment: alignment ?? Alignment.center,
    );
  }


  @Deprecated('Use withTooltip() instead')
  Widget tooltip({required String msg}) {
    return Tooltip(message: msg, child: this);
  }

  /// Validate given widget is not null and returns given value if null.
  Widget withTooltip({required String msg}) {
    return Tooltip(message: msg, child: this);
  }

  /// Make your any widget refreshable with RefreshIndicator on top
  Widget get makeRefreshable {
    return Stack(children: [ListView(), this!]);
  }




}

extension BooleanExtensions on bool? {
  /// Validate given bool is not null and returns given value if null.
  bool validate({bool value = false}) => this ?? value;
}

/// set different layout based on current screen size (mobile, web, desktop)
class Responsive extends StatelessWidget {
  final Widget? web;
  final Widget mobile;
  final Widget? tablet;
  final bool? useFullWidth;
  final double? width;
  final double? minHeight;
  final Widget? defaultWidget;

  Responsive({
    this.web,
    required this.mobile,
    this.tablet,
    this.useFullWidth,
    this.width,
    this.minHeight,
    this.defaultWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.device == DeviceSize.tablet) {
          return tablet ?? mobile;
        } else if (constraints.device == DeviceSize.mobile) {
          return mobile;
        } else if (constraints.device == DeviceSize.desktop) {
          /// $desktopBreakpointGlobal checkout this variable to breakout desktop widget

          if (minHeight != null && constraints.minHeight < minHeight!) {
            return defaultWidget.validate();
          } else {
            return Container(
              alignment: Alignment.topCenter,
              child: Container(
                constraints: useFullWidth.validate(value: true) ? null : BoxConstraints(maxWidth: width ?? (MediaQuery.of(context).size.width * 0.9)),
                child: web ?? SizedBox(),
              ),
            );
          }
        }
        return web ?? tablet ?? mobile;
      },
    );
  }
}
