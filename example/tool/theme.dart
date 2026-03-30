import 'dart:io';

import 'package:stack_theme/stack_theme.dart';

void main() {
  final textColors = <TextColorDescription>[
    .new('primary', getter: 'display.primary'),
    .new('secondary', getter: 'display.secondary'),
    .new('tertiary', getter: 'display.tertiary'),
    .new('accent', getter: 'accent.primary'),
    .new('danger', getter: 'danger.primary'),
  ];

  final themeDescription = ThemeDescription(
    platforms: ['material', 'cupertino'],
    variants: ['purple', 'orange'],
    colors: [
      .group('background', children: [.leaf('primary'), .leaf('secondary')]),
      .group('accent', children: [.surface('primary'), .surface('secondary')]),
      .group('danger', children: [.surface('primary'), .surface('secondary')]),
      .group('display', children: [.leaf('primary'), .leaf('secondary'), .leaf('tertiary')]),
      .group('action', children: [.actionable('primary'), .actionable('secondary'), .actionable('danger')]),
      .group('optionals', children: [.leaf('primary', isOptional: true), .leaf('secondary', isOptional: true)]),
    ],
    typography: [
      .new('simple'),
      .new('brand', weights: [.regular, .bold]),
      .new('largeTitle', colors: textColors),
      .new('title1', colors: textColors, weights: [.regular, .bold]),
      .new('title2', colors: textColors, weights: [.regular, .bold]),
      .new('subtitle1', colors: textColors, weights: [.regular, .bold]),
      .new('body1', colors: textColors, weights: [.regular, .bold]),
      .new('caption1', colors: textColors, weights: [.regular, .bold, .black]),
      .new('caption2', colors: textColors, weights: [.regular, .bold, .black]),
      .new('caption3', colors: textColors, weights: [.regular, .bold, .black]),
      .new('footnote', colors: textColors, weights: [.regular, .bold, .black]),
    ],
    animations: [
      .new('spatialFast'),
      .new('spatialDefault'),
      .new('spatialSlow'),
      .new('effectFast'),
      .new('effectDefault'),
      .new('effectSlow'),
    ],
    shadows: [
      .new('large'),
      .new('medium'),
      .new('small'),
    ],
  );

  final generated = themeDescription.generate();
  final file = File('example/lib/theme.g.dart');
  file.writeAsStringSync(generated.join('\n'));
}
