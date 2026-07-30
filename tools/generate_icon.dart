import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Create a 512x512 image
  final image = Image(width: 512, height: 512);
  
  // Fill with purple background (#6366f1)
  final purple = ColorRgb8(99, 102, 241);
  fill(image, color: purple);
  
  // Draw brain-like shape (simplified brain icon)
  final white = ColorRgb8(255, 255, 255);
  
  // Main brain outline - two hemispheres
  drawCircle(image, x: 200, y: 240, radius: 90, color: white);
  drawCircle(image, x: 312, y: 240, radius: 90, color: white);
  
  // Brain stem/connection
  drawCircle(image, x: 256, y: 240, radius: 50, color: white);
  
  // Inner texture circles
  drawCircle(image, x: 170, y: 200, radius: 25, color: purple);
  drawCircle(image, x: 230, y: 200, radius: 25, color: purple);
  drawCircle(image, x: 282, y: 200, radius: 25, color: purple);
  drawCircle(image, x: 342, y: 200, radius: 25, color: purple);
  
  drawCircle(image, x: 185, y: 260, radius: 20, color: purple);
  drawCircle(image, x: 256, y: 260, radius: 20, color: purple);
  drawCircle(image, x: 327, y: 260, radius: 20, color: purple);
  
  drawCircle(image, x: 200, y: 310, radius: 25, color: purple);
  drawCircle(image, x: 312, y: 310, radius: 25, color: purple);
  
  // Save as PNG
  final file = File('../assets/launcher_icon.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(image));
  
  print('Icon generated successfully at ${file.path}');
}
