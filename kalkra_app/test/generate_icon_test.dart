import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate PNG icon from SVG spec with transparency', () {
    // Generate a high-res image (1024x1024) with transparency support
    final image = img.Image(width: 1024, height: 1024, numChannels: 4);

    // Background: Fully Transparent
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

    final int padding = 60;
    final int gap = 60;
    final int quadSize = (1024 - (padding * 2) - gap) ~/ 2;

    // Colors (Vector Pop)
    final cyan = img.ColorRgba8(0, 229, 255, 255);
    final pink = img.ColorRgba8(255, 64, 129, 255);
    final purple = img.ColorRgba8(124, 77, 255, 255);
    final yellow = img.ColorRgba8(255, 238, 88, 255);
    final transparent = img.ColorRgba8(0, 0, 0, 0); // For cutouts

    // Helper: Rounded corner quadrants
    void drawRoundedQuadrant(
      int x,
      int y,
      int size,
      img.Color color, {
      bool tl = false,
      bool tr = false,
      bool bl = false,
      bool br = false,
    }) {
      final r = 140;
      img.fillRect(
        image,
        x1: x + (tl ? r : 0),
        y1: y,
        x2: x + size - (tr ? r : 0),
        y2: y + size,
        color: color,
      );
      img.fillRect(
        image,
        x1: x,
        y1: y + (tl || tr ? r : 0),
        x2: x + size,
        y2: y + size - (bl || br ? r : 0),
        color: color,
      );

      if (tl)
        img.fillCircle(image, x: x + r, y: y + r, radius: r, color: color);
      if (tr)
        img.fillCircle(
          image,
          x: x + size - r,
          y: y + r,
          radius: r,
          color: color,
        );
      if (bl)
        img.fillCircle(
          image,
          x: x + r,
          y: y + size - r,
          radius: r,
          color: color,
        );
      if (br)
        img.fillCircle(
          image,
          x: x + size - r,
          y: y + size - r,
          radius: r,
          color: color,
        );
    }

    // 1. Draw Exploded Quadrants
    drawRoundedQuadrant(padding, padding, quadSize, cyan, tl: true);
    drawRoundedQuadrant(
      padding + quadSize + gap,
      padding,
      quadSize,
      pink,
      tr: true,
    );
    drawRoundedQuadrant(
      padding,
      padding + quadSize + gap,
      quadSize,
      purple,
      bl: true,
    );
    drawRoundedQuadrant(
      padding + quadSize + gap,
      padding + quadSize + gap,
      quadSize,
      yellow,
      br: true,
    );

    // 2. Draw Negative Space Symbols (Transparent Cutouts)
    // PLUS (TL)
    int tlX = padding + quadSize ~/ 2;
    int tlY = padding + quadSize ~/ 2;
    img.fillRect(
      image,
      x1: tlX - 100,
      y1: tlY - 15,
      x2: tlX + 100,
      y2: tlY + 15,
      color: transparent,
    );
    img.fillRect(
      image,
      x1: tlX - 15,
      y1: tlY - 100,
      x2: tlX + 15,
      y2: tlY + 100,
      color: transparent,
    );
    img.fillCircle(image, x: tlX - 100, y: tlY, radius: 15, color: transparent);
    img.fillCircle(image, x: tlX + 100, y: tlY, radius: 15, color: transparent);
    img.fillCircle(image, x: tlX, y: tlY - 100, radius: 15, color: transparent);
    img.fillCircle(image, x: tlX, y: tlY + 100, radius: 15, color: transparent);

    // MINUS (TR)
    int trX = padding + quadSize + gap + quadSize ~/ 2;
    int trY = padding + quadSize ~/ 2;
    img.fillRect(
      image,
      x1: trX - 100,
      y1: trY - 15,
      x2: trX + 100,
      y2: trY + 15,
      color: transparent,
    );
    img.fillCircle(image, x: trX - 100, y: trY, radius: 15, color: transparent);
    img.fillCircle(image, x: trX + 100, y: trY, radius: 15, color: transparent);

    // MULTIPLY (BL)
    int blX = padding + quadSize ~/ 2;
    int blY = padding + quadSize + gap + quadSize ~/ 2;
    for (int i = -12; i <= 12; i++) {
      img.drawLine(
        image,
        x1: blX - 80 + i,
        y1: blY - 80,
        x2: blX + 80 + i,
        y2: blY + 80,
        color: transparent,
      );
      img.drawLine(
        image,
        x1: blX + 80 + i,
        y1: blY - 80,
        x2: blX - 80 + i,
        y2: blY + 80,
        color: transparent,
      );
    }

    // DIVIDE (BR)
    int brX = padding + quadSize + gap + quadSize ~/ 2;
    int brY = padding + quadSize + gap + quadSize ~/ 2;
    img.fillRect(
      image,
      x1: brX - 100,
      y1: brY - 15,
      x2: brX + 100,
      y2: brY + 15,
      color: transparent,
    );
    img.fillCircle(image, x: brX - 100, y: brY, radius: 15, color: transparent);
    img.fillCircle(image, x: brX + 100, y: brY, radius: 15, color: transparent);
    img.fillCircle(image, x: brX, y: brY - 80, radius: 25, color: transparent);
    img.fillCircle(image, x: brX, y: brY + 80, radius: 25, color: transparent);

    final png = img.encodePng(image);
    File('assets/images/app_icon.png').writeAsBytesSync(png);
  });
}
