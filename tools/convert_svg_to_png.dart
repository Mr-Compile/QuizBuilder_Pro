import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Create a 512x512 image
  final image = img.Image(width: 512, height: 512);
  
  // Fill with green background (#10b981 - emerald green)
  final green = img.ColorRgb8(16, 185, 129);
  img.fill(image, color: green);
  
  // Draw a simple brain shape as fallback
  final white = img.ColorRgb8(255, 255, 255);
  
  // Left hemisphere
  _drawBrainHemisphere(image, 180, 256, 120, white, green);
  // Right hemisphere  
  _drawBrainHemisphere(image, 332, 256, 120, white, green);
  
  // Brain stem at bottom
  _drawBrainStem(image, 256, 380, white, green);
  
  // Central connection
  img.drawCircle(image, x: 256, y: 256, radius: 60, color: white);
  
  // Save as PNG
  final file = File('../assets/brain_icon.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  
  print('Icon generated successfully at ${file.path}');
}

void _drawBrainHemisphere(img.Image image, int centerX, int centerY, int radius, img.ColorRgb8 mainColor, img.ColorRgb8 bgColor) {
  // Main hemisphere shape
  img.drawCircle(image, x: centerX, y: centerY, radius: radius, color: mainColor);
  
  // Brain folds (gyri) - more realistic pattern
  // Top folds
  img.drawCircle(image, x: centerX - 40, y: centerY - 50, radius: 25, color: bgColor);
  img.drawCircle(image, x: centerX + 20, y: centerY - 60, radius: 30, color: bgColor);
  img.drawCircle(image, x: centerX + 50, y: centerY - 40, radius: 20, color: bgColor);
  
  // Middle folds
  img.drawCircle(image, x: centerX - 50, y: centerY, radius: 28, color: bgColor);
  img.drawCircle(image, x: centerX + 10, y: centerY + 10, radius: 25, color: bgColor);
  img.drawCircle(image, x: centerX + 45, y: centerY - 5, radius: 22, color: bgColor);
  
  // Bottom folds
  img.drawCircle(image, x: centerX - 35, y: centerY + 45, radius: 24, color: bgColor);
  img.drawCircle(image, x: centerX + 15, y: centerY + 55, radius: 28, color: bgColor);
  img.drawCircle(image, x: centerX + 50, y: centerY + 35, radius: 20, color: bgColor);
  
  // Side folds
  img.drawCircle(image, x: centerX - 70, y: centerY - 20, radius: 18, color: bgColor);
  img.drawCircle(image, x: centerX - 65, y: centerY + 25, radius: 20, color: bgColor);
  img.drawCircle(image, x: centerX + 70, y: centerY - 15, radius: 18, color: bgColor);
  img.drawCircle(image, x: centerX + 68, y: centerY + 30, radius: 19, color: bgColor);
}

void _drawBrainStem(img.Image image, int centerX, int centerY, img.ColorRgb8 mainColor, img.ColorRgb8 bgColor) {
  // Brain stem - rectangular shape at bottom
  const stemWidth = 40;
  const stemHeight = 50;
  
  for (int y = centerY; y < centerY + stemHeight; y++) {
    for (int x = centerX - stemWidth ~/ 2; x < centerX + stemWidth ~/ 2; x++) {
      image.setPixel(x, y, mainColor);
    }
  }
  
  // Stem details
  img.drawCircle(image, x: centerX, y: centerY + stemHeight - 10, radius: 12, color: bgColor);
}