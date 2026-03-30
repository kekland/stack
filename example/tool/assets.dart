import 'dart:io';

import 'package:stack_assets/stack_assets.dart';

Future<void> main() async {
  final output = await generateAssets(
    AssetManifest(
      rootDirectory: Directory('example'),
      assetsDirectory: Directory('example/assets'),
      inputDirectoryName: 'dev',
      outputDirectoryName: 'gen',
      categoryResolvers: {
        'icons': [
          .new(type: 'ThemePlatform', name: 'platform', getter: 'context.themePlatform'),
          .new(type: 'Brightness', name: 'brightness', getter: 'context.brightness'),
        ],
      },
      prelude: [
        'import \'package:example/theme.g.dart\';',
        'import \'package:stack_ui/stack_ui.dart\';',
      ],
    ),
  );

  final assetsFile = File('example/lib/assets.g.dart');
  assetsFile.writeAsStringSync(output.join('\n'));
}
