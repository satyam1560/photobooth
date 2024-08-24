import 'dart:io';

import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as pathJoiner;
import 'package:path_provider/path_provider.dart';
import 'package:photobooth_qr/src/core/utility/camera_image-data.dart';
import 'package:photobooth_qr/src/photobooth/backend/db.dart';
import 'package:photobooth_qr/src/photobooth/ui/widgets/qr_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  CapturePageState createState() => CapturePageState();
}

class CapturePageState extends State<CapturePage> {
  CameraMacOSController? macOSController;
  late CameraMacOSMode cameraMode;
  late TextEditingController durationController;
  late double durationValue;
  Uint8List? lastImagePreviewData;
  Uint8List? lastRecordedVideoData;
  GlobalKey cameraKey = GlobalKey();
  List<CameraMacOSDevice> videoDevices = [];
  String? selectedVideoDevice;
  File? lastPictureTaken;
  bool enableAudio = false;
  bool enableTorch = false;
  bool usePlatformView = false;
  bool streamImage = false;
  String? _downloadUrl;

  CameraImageData? streamedImage;

  double zoom = 1.0;

  List<DropdownMenuItem<String>> add = [];

  @override
  void initState() {
    super.initState();
    cameraMode = CameraMacOSMode.photo;
    durationValue = 15;
    durationController = TextEditingController(text: "$durationValue");
    durationController.addListener(() {
      setState(() {
        double? textFieldContent = double.tryParse(durationController.text);
        if (textFieldContent == null) {
          durationValue = 15;
          durationController.text = "$durationValue";
        } else {
          durationValue = textFieldContent;
        }
      });
    });

    for (int i = 0; i < AudioFormat.values.length; i++) {
      add.add(DropdownMenuItem(
        value: '$i',
        child: Text(AudioFormat.values[i].name.replaceAll('kAudioFormat', '')),
      ));
    }
  }

  String get cameraButtonText {
    String label = "Do something";
    switch (cameraMode) {
      case CameraMacOSMode.photo:
        label = "Take Picture";
        break;
      case CameraMacOSMode.video:
        if (macOSController?.isRecording ?? false) {
          label = "Stop recording";
        } else {
          label = "Record video";
        }
        break;
    }
    return label;
  }

  // Future<String> get imageFilePath async => pathJoiner.join(
  //     (await getApplicationDocumentsDirectory()).path,
  //     "P_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.png");
  Future<String> get imageFilePath async {
    // Example logic to generate file path
    final directory = await getApplicationDocumentsDirectory();
    return pathJoiner.join(
      directory.path,
      "P_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.png",
    );
  }

  Future<String> get videoFilePath async => pathJoiner.join(
      (await getApplicationDocumentsDirectory()).path,
      "V_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.png");

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera MacOS Example'),
      ),
      body: SizedBox(
          width: size.width,
          height: size.height,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Video Devices",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: DropdownButton<String>(
                                  elevation: 3,
                                  isExpanded: true,
                                  value: selectedVideoDevice,
                                  underline:
                                      Container(color: Colors.transparent),
                                  items: videoDevices
                                      .map((CameraMacOSDevice device) {
                                    return DropdownMenuItem(
                                      value: device.deviceId,
                                      child: Text(device.deviceId),
                                    );
                                  }).toList(),
                                  onChanged: (String? newDeviceID) {
                                    setState(() {
                                      selectedVideoDevice = newDeviceID;
                                    });
                                  },
                                ),
                              ),
                            ),
                            MaterialButton(
                              color: Colors.lightBlue,
                              textColor: Colors.white,
                              onPressed: listVideoDevices,
                              child: const Text("List video devices"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        selectedVideoDevice != null &&
                                selectedVideoDevice!.isNotEmpty
                            ? SizedBox(
                                width: (size.width - 24),
                                height: (size.width - 24) * (9 / 16),
                                child: GestureDetector(
                                  onTapDown: (t) {
                                    macOSController?.setFocusPoint(Offset(
                                        t.localPosition.dx / (size.width - 24),
                                        t.localPosition.dy /
                                            ((size.width - 24) * (9 / 16))));
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 40),
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
                                      // toggleTorch:
                                      //     enableTorch ? Torch.on : Torch.off,
                                      enableAudio: enableAudio,
                                      usePlatformView: usePlatformView,
                                    ),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text("Tap on List Devices first"),
                              ),
                        lastImagePreviewData != null
                            ? InkWell(
                                onTap: openPicture,
                                child: Container(
                                  decoration: ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                        color: Colors.lightBlue,
                                        width: 10,
                                      ),
                                    ),
                                  ),
                                  child: Image.memory(
                                    lastImagePreviewData!,
                                    height: 50,
                                    width: 90,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (streamedImage != null)
                      SizedBox(
                          width: (size.width - 24),
                          height: (size.width - 24) * (9 / 16),
                          child:
                              Image.memory(argb2bitmap(streamedImage!).bytes)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MaterialButton(
                          color: Colors.red,
                          textColor: Colors.white,
                          onPressed: destroyCamera,
                          child: Builder(
                            builder: (context) {
                              String buttonText = "Destroy";
                              if (macOSController != null &&
                                  macOSController!.isDestroyed) {
                                buttonText = "Reinitialize";
                              }
                              return Text(buttonText);
                            },
                          ),
                        ),
                        MaterialButton(
                          color: Colors.lightBlue,
                          textColor: Colors.white,
                          onPressed: onCameraButtonTap,
                          child: Text(cameraButtonText),
                        ),
                      ],
                    ),
                    if (_downloadUrl != null)
                      MyWidget(downloadUrl: _downloadUrl!),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Future<void> startRecording() async {
    try {
      String urlPath = await videoFilePath;
      await macOSController!.recordVideo(
        maxVideoDuration: durationValue,
        url: urlPath,
        enableAudio: enableAudio,
        onVideoRecordingFinished:
            (CameraMacOSFile? result, CameraMacOSException? exception) {
          setState(() {});
          if (exception != null) {
            showAlert(message: exception.toString());
          } else if (result != null) {
            showAlert(
              title: "SUCCESS",
              message: "Video saved at ${result.url}",
            );
          }
        },
      );
    } catch (e) {
      showAlert(message: e.toString());
    } finally {
      setState(() {});
    }
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

  Future<void> onCameraButtonTap() async {
    try {
      if (macOSController != null) {
        switch (cameraMode) {
          case CameraMacOSMode.photo:
            CameraMacOSFile? imageData = await macOSController!.takePicture();
            if (imageData != null) {
              setState(() {
                lastImagePreviewData = imageData.bytes;
                savePicture(lastImagePreviewData!);
              });
              showAlert(
                title: "SUCCESS",
                message: "Image successfully created",
              );
            }
            break;
          case CameraMacOSMode.video:
            if (macOSController!.isRecording) {
              CameraMacOSFile? videoData =
                  await macOSController!.stopRecording();
              if (videoData != null) {
                setState(() {
                  lastRecordedVideoData = videoData.bytes;
                });
                showAlert(
                  title: "SUCCESS",
                  message: "Video saved at ${videoData.url}",
                );
              }
            } else {
              startRecording();
            }
            break;
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

  Future<void> openPicture() async {
    try {
      if (lastPictureTaken != null) {
        Uri uriPath = Uri.file(lastPictureTaken!.path);
        if (await canLaunchUrl(uriPath)) {
          await launchUrl(uriPath);
        }
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  void startImageStream() async {
    try {
      if (macOSController != null && !macOSController!.isStreamingImageData) {
        print("Started streaming");
        setState(() {
          macOSController!.startImageStream(
            (p0) {
              print(p0.toString());
            },
          );
        });
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  void stopImageStream() async {
    try {
      if (macOSController != null && macOSController!.isStreamingImageData) {
        setState(() {
          macOSController!.stopImageStream();
          print("Stopped streaming");
        });
      }
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
}
