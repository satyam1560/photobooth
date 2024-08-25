import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyWidget extends StatelessWidget {
  final String downloadUrl;
  const MyWidget({super.key, required this.downloadUrl});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: downloadUrl,  
      version: QrVersions.auto,
      size: 320,
      gapless: false,
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(80, 80),
      ),
    );
  }
}
