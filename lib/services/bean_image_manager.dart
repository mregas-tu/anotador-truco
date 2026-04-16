import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../widgets/bean_widget.dart';
import '../providers/score_provider.dart';

class BeanImageManager {
  static final BeanImageManager _instance = BeanImageManager._internal();
  factory BeanImageManager() => _instance;
  BeanImageManager._internal();

  ui.Image? _cachedImage;
  BeanType? _cachedType;
  double? _cachedSize;

  ui.Image? get cachedImage => _cachedImage;
  BeanType? get cachedType => _cachedType;

  Future<void> cacheBean(BeanType type, double size) async {
    // Si ya es el mismo tipo y tamaño, no hacemos nada
    if (_cachedType == type && _cachedSize == size && _cachedImage != null) {
      return;
    }

    _cachedImage?.dispose();
    _cachedImage = null;
    _cachedType = type;
    _cachedSize = size;

    // Usamos un factor de escala para que se vea nítido (Retina/High DPI)
    const double pixelRatio = 4.0;
    final double widthFactor = 1.6;
    final double w = size * widthFactor;
    final double h = size;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio); // Escalamos el dibujo
    
    final painter = BeanPainter(seed: 0, beanType: type);
    painter.paint(canvas, Size(w, h));

    final picture = recorder.endRecording();
    _cachedImage = await picture.toImage((w * pixelRatio).toInt(), (h * pixelRatio).toInt());
    picture.dispose();
  }

  void clear() {
    _cachedImage?.dispose();
    _cachedImage = null;
    _cachedType = null;
    _cachedSize = null;
  }
}
