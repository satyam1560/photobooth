import 'dart:async';
import 'dart:io';

import 'package:camera_macos/camera_macos.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
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
  bool isLoading = false;
  //windows
  int _cameraId = -1;
  late CameraPlatform _cameraPlatform;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      cameraMode = CameraMacOSMode.photo;
      listVideoDevices();
    } else if (Platform.isWindows) {
      _cameraPlatform = CameraPlatform.instance;
      _fetchCameras();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'PhotoBooth',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          //* Camera Preview
          if (selectedVideoDevice != null &&
              selectedVideoDevice!.isNotEmpty &&
              Platform.isMacOS) ...{
            CameraMacOSView(
              key: cameraKey,
              deviceId: selectedVideoDevice,
              fit: BoxFit.cover,
              cameraMode: CameraMacOSMode.photo,
              pictureFormat: PictureFormat.png,
              onCameraInizialized: (CameraMacOSController controller) {
                setState(() {
                  macOSController = controller;
                });
              },
              onCameraDestroyed: () {
                return const Text("Camera Destroyed!");
              },
              enableAudio: enableAudio,
              usePlatformView: usePlatformView,
            )
          } else ...{
            Center(
              child: lastImagePreviewData == null
                  ? (_isCameraInitialized
                      ? _cameraPlatform.buildPreview(_cameraId)
                      : const CircularProgressIndicator())
                  : Container(
                      constraints: const BoxConstraints.expand(),
                      child: Image.memory(
                        lastImagePreviewData!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          },
          //* Display Image
          if (lastImagePreviewData != null) ...{
            Image.memory(
              lastImagePreviewData!,
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
            )
          },

          //* Buttons
          if (isImageCaptured) ...[
            Align(
              alignment: Alignment.bottomRight,
              child: InkWell(
                onTap: () async {
                  setState(() {
                    isLoading = true;
                  });

                  await savePicture(lastImagePreviewData!);

                  if (_downloadUrl != null) {
                    setState(() {
                      isLoading = false;
                    });
                    showQRCodeDialog(context, _downloadUrl!);
                  } else {
                    setState(() {
                      isLoading = false;
                    });
                    // Handle the case where _downloadUrl is null
                  }

                  print('show QR code');
                },
                child: Image.asset(
                  'assets/go_next_button_icon.png',
                  height: 60,
                  width: 60,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: InkWell(
                onTap: () async {
                  setState(() {
                    isImageCaptured = false;
                    lastImagePreviewData = null;
                  });
                  if (Platform.isMacOS) {
                    if (macOSController != null) {
                      await destroyCamera();
                    }
                    await listVideoDevices();
                  } else {
                    _reinitializeCamera();
                  }
                },
                child: Image.asset(
                  'assets/retake_button_icon.png',
                  height: 60,
                  width: 60,
                ),
              ),
            ),
            isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color.fromARGB(255, 225, 222, 222),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Processing....',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: const Color.fromARGB(255, 225, 222, 222),
                              ),
                        ),
                      ],
                    ),
                  )
                : Container(), // Show loading indicator
          ] else ...[
            Align(
              alignment: Alignment.bottomCenter,
              child: ShutterButton(
                key: const Key('photoboothPreview_photo_shutterButton'),
                onCountdownComplete: () async {
                  await captureImage();
                  if (Platform.isMacOS) {
                    setState(() {
                      isImageCaptured = true;
                    });
                    destroyCamera();
                  } else {
                    setState(() {
                      isImageCaptured = true;
                    });
                    _takePicture();
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _fetchCameras() async {
    List<CameraDescription> cameras = await _cameraPlatform.availableCameras();
    _initializeCamera(cameras.first);
    setState(() {});
  }

  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      _cameraId = await _cameraPlatform.createCamera(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraPlatform.initializeCamera(_cameraId);

      setState(() {
        _isCameraInitialized = true;
        lastImagePreviewData = null;
      });
    } on PlatformException catch (e) {
      print('Initialisation Error: ${e.toString()}');
    }
  }

  Future<void> _reinitializeCamera() async {
    if (_isCameraInitialized) {
      await _cameraPlatform.dispose(_cameraId);
    }
    _fetchCameras();
  }

  Future<void> _takePicture() async {
    final XFile file = await _cameraPlatform.takePicture(_cameraId);
    Uint8List imageBytes = await file.readAsBytes();
    img.Image originalImage = img.decodeImage(imageBytes)!;
    img.Image flippedImage = img.flipHorizontal(originalImage);
    lastImagePreviewData = Uint8List.fromList(img.encodeJpg(flippedImage));
    await _cameraPlatform.dispose(_cameraId);

    setState(() {
      _isCameraInitialized = false;
    });
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
            // savePicture(lastImagePreviewData!);
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

  @override
  void dispose() {
    if (Platform.isWindows) {
      if (_isCameraInitialized) {
        _cameraPlatform.dispose(_cameraId);
      }
    } else {
      destroyCamera();
    }
    super.dispose();
  }
}

Future<void> showQRCodeDialog(BuildContext context, String url) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Scan to download Capture',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
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
              print('url:$url');
              Navigator.of(context).pop();
              StoreDbFile().deleteFileFromFirebase(fileUrl: url);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
