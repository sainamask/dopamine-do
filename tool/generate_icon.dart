// Brutalist app-icon generator. Paints two PNGs:
//   - assets/icon/app_icon.png            (legacy + iOS master, 1024x1024)
//   - assets/icon/app_icon_foreground.png (Android adaptive foreground)
//
// Style matches the app: chunky black border, hard offset shadow, vivid
// pink fill, white lightning bolt centered. Run with:
//
//   dart run tool/generate_icon.dart
//
// Then run `dart run flutter_launcher_icons` to slot it into the
// per-density mipmap folders.
import 'dart:io';
import 'package:image/image.dart' as img;

// Palette (mirrors lib/theme/app_colors.dart).
final img.Color _ink = img.ColorRgb8(0x17, 0x17, 0x17);
final img.Color _paper = img.ColorRgb8(0xEE, 0xEA, 0xE0);
final img.Color _pink = img.ColorRgb8(0xD9, 0x46, 0x8D);
final img.Color _white = img.ColorRgb8(0xFF, 0xFF, 0xFF);

const int _size = 1024;

void main() {
  _writeLegacyIcon();
  _writeAdaptiveForeground();
  // ignore: avoid_print
  print(
    'Wrote assets/icon/app_icon.png and assets/icon/app_icon_foreground.png',
  );
}

/// Square icon used on iOS + the Android legacy launcher.
void _writeLegacyIcon() {
  final img.Image image = img.Image(width: _size, height: _size);
  img.fill(image, color: _paper);

  // Hard offset shadow (~50px down-right). Brutalist signature.
  const int shadowOffset = 56;
  _filledRect(
    image,
    left: 120 + shadowOffset,
    top: 120 + shadowOffset,
    right: _size - 80 + shadowOffset,
    bottom: _size - 80 + shadowOffset,
    color: _ink,
  );

  // Black-bordered pink card.
  _filledRect(
    image,
    left: 120,
    top: 120,
    right: _size - 80,
    bottom: _size - 80,
    color: _ink,
  );
  const int border = 36;
  _filledRect(
    image,
    left: 120 + border,
    top: 120 + border,
    right: _size - 80 - border,
    bottom: _size - 80 - border,
    color: _pink,
  );

  _drawBolt(image);

  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(image));
}

/// Adaptive foreground: same bolt without the card chrome. The Android
/// launcher composites it on top of the pink background colour declared
/// in pubspec.yaml, then masks to whatever shape the launcher prefers.
void _writeAdaptiveForeground() {
  // Adaptive icons are 1024 master with a generous safe zone — only the
  // center ~66% is guaranteed visible. We paint the bolt at the same
  // proportions, no card.
  final img.Image image = img.Image(
    width: _size,
    height: _size,
    numChannels: 4,
  );
  // Transparent background.
  for (int y = 0; y < _size; y++) {
    for (int x = 0; x < _size; x++) {
      image.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }
  _drawBolt(image);
  File(
    'assets/icon/app_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(image));
}

/// Filled rectangle (inclusive of the right/bottom edges).
void _filledRect(
  img.Image image, {
  required int left,
  required int top,
  required int right,
  required int bottom,
  required img.Color color,
}) {
  img.fillRect(
    image,
    x1: left,
    y1: top,
    x2: right,
    y2: bottom,
    color: color,
  );
}

/// A chunky white lightning bolt with a hard ink shadow, centered.
/// Defined as a closed polygon, 7 vertices, clockwise from the top.
void _drawBolt(img.Image image) {
  // Designed inside a 1024 square; the bolt itself spans roughly
  // (300..720) horizontally and (200..820) vertically.
  final List<img.Point> bolt = <img.Point>[
    img.Point(580, 200), // top-right (apex)
    img.Point(340, 540), // mid-left bend outer
    img.Point(460, 540), // mid-left bend inner
    img.Point(380, 820), // bottom tip
    img.Point(680, 520), // mid-right bend outer (going back up)
    img.Point(560, 520), // mid-right bend inner
    img.Point(640, 200), // top-left
  ];

  // Hard offset shadow underneath.
  const int shadowOffset = 28;
  final List<img.Point> shadow = bolt
      .map((img.Point p) => img.Point(p.x + shadowOffset, p.y + shadowOffset))
      .toList();
  img.fillPolygon(image, vertices: shadow, color: _ink);

  // Bolt itself.
  img.fillPolygon(image, vertices: bolt, color: _white);

  // Thick ink outline on the bolt — same polygon as a stroke.
  _strokePolygon(image, vertices: bolt, color: _ink, thickness: 12);
}

/// Strokes a closed polygon by drawing thick lines between consecutive
/// vertices (and back to the first). Used as a thick outline.
void _strokePolygon(
  img.Image image, {
  required List<img.Point> vertices,
  required img.Color color,
  required num thickness,
}) {
  for (int i = 0; i < vertices.length; i++) {
    final img.Point a = vertices[i];
    final img.Point b = vertices[(i + 1) % vertices.length];
    img.drawLine(
      image,
      x1: a.x.toInt(),
      y1: a.y.toInt(),
      x2: b.x.toInt(),
      y2: b.y.toInt(),
      color: color,
      thickness: thickness.toDouble(),
    );
  }
}
