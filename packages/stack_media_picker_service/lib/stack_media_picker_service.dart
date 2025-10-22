import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stack/stack.dart';
import 'package:croppy/croppy.dart' as croppy;

class MediaPickerService extends Service {
  MediaPickerService() : super(logger: Logger('MediaPickerService'));

  Future<File?> pickSingleImage({
    List<croppy.CropAspectRatio>? allowedAspectRatios,
  }) async {
    return serviceMethodAsync(logger, () async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2000, maxHeight: 2000);
      if (image == null) return null;

      logger.fine('Picked image path: ${image.path}');
      final imageProvider = FileImage(File(image.path));

      final result = await croppy.showAdaptiveImageCropper(
        // ignore: use_build_context_synchronously
        belowNavigatorContext,
        imageProvider: imageProvider,
        allowedAspectRatios: allowedAspectRatios,
      );

      if (result == null) return null;
      logger.fine('Cropped image data: ${result.uiImage.width}x${result.uiImage.height}. Saving to temp.');
      final bytes = await result.uiImage.toByteData(format: ImageByteFormat.png);

      final temp = await getTemporaryDirectory();
      final randomName = DateTime.now().millisecondsSinceEpoch.toString();
      final savedImagePath = '${temp.path}/cropped_$randomName.png';
      final savedImageFile = File(savedImagePath);
      await savedImageFile.writeAsBytes(bytes!.buffer.asUint8List());
      result.uiImage.dispose();

      logger.fine('Cropped image saved to: $savedImagePath');
      return savedImageFile;
    });
  }
}
