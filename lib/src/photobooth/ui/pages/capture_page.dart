import 'dart:async';
import 'dart:io';

import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as pathJoiner;
import 'package:path_provider/path_provider.dart';
import 'package:photobooth_qr/src/photobooth/backend/db.dart';
import 'package:photobooth_qr/src/photobooth/ui/widgets/qr_widget.dart';
import 'package:photobooth_qr/src/photobooth/ui/widgets/shutter_button.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  CapturePageState createState() => CapturePageState();
}

class CapturePageState extends State<CapturePage> {
  CameraMacOSController? macOSController;
  late CameraMacOSMode cameraMode;
  Uint8List? lastImagePreviewData;
  GlobalKey cameraKey = GlobalKey();
  List<CameraMacOSDevice> videoDevices = [];
  String? selectedVideoDevice;
  File? lastPictureTaken;
  bool enableAudio = false;
  bool enableTorch = false;
  bool usePlatformView = false;
  bool streamImage = false;
  String? _downloadUrl;
  bool isImageCaptured = false;
  @override
  void initState() {
    super.initState();
    cameraMode = CameraMacOSMode.photo;
    listVideoDevices();
  }

  String get cameraButtonText {
    if (cameraMode == CameraMacOSMode.photo) {
      return "Take Picture";
    }
    return "Do something";
  }

  Future<String> get imageFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return pathJoiner.join(
      directory.path,
      "P_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.png",
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'PhotoBooth',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background_image.jpg',
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 80),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                lastImagePreviewData != null
                    ? SizedBox(
                        height: (size.width - 24) * (9 / 16),
                        child: Stack(
                          children: [
                            Image.memory(
                              lastImagePreviewData!,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    isImageCaptured = false;
                                    lastImagePreviewData = null;
                                  });
                                },
                                child: Image.asset(
                                  'assets/retake_button_icon.png',
                                  height: 60,
                                  width: 60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : (selectedVideoDevice != null &&
                            selectedVideoDevice!.isNotEmpty)
                        ? SizedBox(
                            height: (size.width - 24) * (9 / 16),
                            child: CameraMacOSView(
                              key: cameraKey,
                              deviceId: selectedVideoDevice,
                              fit: BoxFit.fitWidth,
                              cameraMode: CameraMacOSMode.photo,
                              pictureFormat: PictureFormat.png,
                              onCameraInizialized:
                                  (CameraMacOSController controller) {
                                setState(() {
                                  macOSController = controller;
                                });
                              },
                              onCameraDestroyed: () {
                                return const Text("Camera Destroyed!");
                              },
                              enableAudio: enableAudio,
                              usePlatformView: usePlatformView,
                            ),
                          )
                        : const SizedBox.shrink(),
                isImageCaptured
                    ? InkWell(
                        onTap: () {
                          if (_downloadUrl != null) {
                            showQRCodeDialog(context, _downloadUrl!);
                          }
                        },
                        child: Image.asset(
                          'assets/go_next_button_icon.png',
                          height: 60,
                          width: 60,
                        ),
                      )
                    : ShutterButton(
                        key: const Key('photoboothPreview_photo_shutterButton'),
                        onCountdownComplete: () async {
                          await captureImage();
                          setState(() {
                            isImageCaptured = true;
                          });
                          destroyCamera();
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> listVideoDevices() async {
    try {
      List<CameraMacOSDevice> videoDevices =
          await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );
      setState(() {
        this.videoDevices = videoDevices;
        if (videoDevices.isNotEmpty) {
          selectedVideoDevice = videoDevices.first.deviceId;
        }
      });
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> destroyCamera() async {
    try {
      if (macOSController != null) {
        if (macOSController!.isDestroyed) {
          setState(() {
            cameraKey = GlobalKey();
          });
        } else {
          await macOSController?.destroy();
          setState(() {});
        }
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> savePicture(Uint8List photoBytes) async {
    try {
      String filename = await imageFilePath;
      File f = File(filename);
      if (f.existsSync()) {
        f.deleteSync(recursive: true);
      }
      f.createSync(recursive: true);
      f.writeAsBytesSync(photoBytes);
      lastPictureTaken = f;
      String imageUrl = await StoreDbFile().generateUrl(memoryPath: filename);
      print('captured imafe url $imageUrl');
      _downloadUrl = imageUrl;
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> showAlert({
    String title = "ERROR",
    String message = "",
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> captureImage() async {
    if (macOSController != null) {
      try {
        final CameraMacOSFile? imageData = await macOSController!.takePicture();
        if (imageData != null) {
          setState(() {
            lastImagePreviewData = imageData.bytes;
            savePicture(lastImagePreviewData!);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Captured Successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

Future<void> showQRCodeDialog(BuildContext context, String url) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Scan to download Capture'),
        contentPadding: const EdgeInsets.all(16.0),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300,
            maxWidth: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_double_arrow_down_outlined,
                size: 50,
              ),
              SizedBox(
                height: 200,
                width: 200,
                child: MyWidget(
                  downloadUrl: url,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
