import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Create a 512x512 image
  final image = Image(width: 512, height: 512);
  
  // Fill with purple background (#6366f1)
  final purple = ColorRgb8(99, 102, 241);
  fill(image, color: purple);
  
  // Draw brain-like shape (simplified brain icon matching login page design)
  final white = ColorRgb8(255, 255, 255);
  
  // Main brain outline - two hemispheres (larger and more prominent)
  drawCircle(image, x: 180, y: 256, radius: 110, color: white);
  drawCircle(image, x: 332, y: 256, radius: 110, color: white);
  
  // Brain stem/connection (more prominent)
  drawCircle(image, x: 256, y: 256, radius: 70, color: white);
  
  // Inner texture circles (brain folds pattern)
  // Top row
  drawCircle(image, x: 150, y: 200, radius: 30, color: purple);
  drawCircle(image, x: 220, y: 190, radius: 35, color: purple);
  drawCircle(image, x: 292, y: 190, radius: 35, color: purple);
  drawCircle(image, x: 362, y: 200, radius: 30, color: purple);
  
  // Middle row
  drawCircle(image, x: 160, y: 270, radius: 25, color: purple);
  drawCircle(image, x: 256, y: 280, radius: 30, color: purple);
  drawCircle(image, x: 352, y: 270, radius: 25, color: purple);
  
  // Bottom row
  drawCircle(image, x: 180, y: 330, radius: 30, color: purple);
  drawCircle(image, x: 332, y: 330, radius: 30, color: purple);
  
  // Additional detail circles for more brain-like appearance
  drawCircle(image, x: 130, y: 240, radius: 20, color: purple);
  drawCircle(image, x: 382, y: 240, radius: 20, color: purple);
  
  // Save as PNG
  final file = File('../assets/launcher_icon.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(image));
  
  // Icon generated successfully at ${file.path}
}
