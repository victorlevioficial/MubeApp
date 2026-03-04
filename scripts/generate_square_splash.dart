import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  const inputPath = 'assets/images/logos_png/logo_vertical.png';
  const outputPath = 'assets/images/logos_png/logo_vertical_square.png';

  print('Reading $inputPath...');
  final bytes = await File(inputPath).readAsBytes();
  final image = img.decodePng(bytes);

  if (image == null) {
    print('Error: Could not decode image.');
    exit(1);
  }

  print('Original size: ${image.width}x${image.height}');

  // Calculate square size: max dimension * 1.5 to ensure it fits safely inside the circular mask
  // Android 12 splash icon view is a circle.
  final size =
      (image.width > image.height ? image.width : image.height) *
      12 ~/
      10; // 20% padding

  print('Creating square canvas: ${size}x$size');
  final mergedImage = img.Image(width: size, height: size, numChannels: 4);

  // Center the image
  final dstX = (size - image.width) ~/ 2;
  final dstY = (size - image.height) ~/ 2;

  img.compositeImage(mergedImage, image, dstX: dstX, dstY: dstY);

  print('Saving to $outputPath...');
  await File(outputPath).writeAsBytes(img.encodePng(mergedImage));
  print('Done.');
}
