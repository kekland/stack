import 'package:stack_theme/stack_theme.dart';

class ThemeDescription {
  const ThemeDescription({
    required this.colors,
    required this.typography,
    this.animations = const [],
    this.shadows = const [],
    this.platforms = const [],
    this.variants = const [],
  });

  final List<String> platforms;
  final List<String> variants;
  final List<ColorDescription> colors;
  final List<TextStyleDescription> typography;
  final List<AnimationStyleDescription> animations;
  final List<ShadowDescription> shadows;

  List<String> generate() => generateThemeFromDescription(this);
}

enum Brightness {
  light,
  dark,
}

//
// Colors
//

abstract class ColorDescription {
  const ColorDescription(this.name, {this.isOptional = false});
  const factory ColorDescription.leaf(String name, {bool isOptional}) = LeafColorDescription;
  const factory ColorDescription.group(String name, {
    required List<ColorDescription> children,
    bool isOptional,
  }) = GroupColorDescription;
  const factory ColorDescription.surface(String name, {bool isOptional}) = SurfaceColorDescription;
  const factory ColorDescription.actionable(String name, {bool isOptional}) = ActionableColorDescription;

  final String name;
  final bool isOptional;
}

class LeafColorDescription extends ColorDescription {
  const LeafColorDescription(super.name, {super.isOptional});
}

abstract class CustomColorDescription extends ColorDescription {
  const CustomColorDescription(super.name, {super.isOptional});

  String get className;
  List<ColorDescription> get children;
}

class GroupColorDescription extends CustomColorDescription {
  const GroupColorDescription(super.name, {required this.children, super.isOptional});

  @override
  String get className => '${name}Colors';

  @override
  final List<ColorDescription> children;
}

class SurfaceColorDescription extends CustomColorDescription {
  const SurfaceColorDescription(super.name, {super.isOptional});

  @override
  String get className => 'SurfaceColor';

  @override
  List<ColorDescription> get children => [
    .leaf('background'),
    .leaf('foreground'),
  ];
}

class ActionableColorDescription extends CustomColorDescription {
  const ActionableColorDescription(super.name, {super.isOptional});

  @override
  String get className => 'ActionableColor';

  @override
  List<ColorDescription> get children => [
    .surface('idle'),
    .surface('hovered', isOptional: true),
    .surface('pressed', isOptional: true),
    .surface('disabled'),
  ];
}

//
// Text style
//

class TextColorDescription {
  const TextColorDescription(this.name, {required this.getter});

  final String name;
  final String getter;
}

enum FontWeight {
  thin, // 100
  extraLight, // 200
  light, // 300
  regular, // 400
  medium, // 500
  semiBold, // 600
  bold, // 700
  extraBold, // 800
  black, // 900
}

class TextStyleDescription {
  const TextStyleDescription(this.name, {this.weights = const <FontWeight>[], this.colors = const <TextColorDescription>[]});

  final String name;
  final List<FontWeight> weights;
  final List<TextColorDescription> colors;

  bool get hasWeights => weights.isNotEmpty;
  bool get hasColors => colors.isNotEmpty;
}

//
// Other stuff
//

class AnimationStyleDescription {
  const AnimationStyleDescription(this.name);

  final String name;
}

class ShadowDescription {
  const ShadowDescription(this.name);

  final String name;
}
