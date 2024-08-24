import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:photobooth_qr/firebase_options.dart';
import 'package:photobooth_qr/src/photobooth/ui/pages/capture_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CapturePage(),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//   String? _downloadUrl;

//   Future<void> uploadImage() async {
//     try {
//       // Path to the image asset
//       String imagePath = 'assets/sample_image.png'; // Ensure this path is correct

//       // Create a reference to the Firebase Storage location
//       Reference storageRef = _storage.ref().child('uploads/sample_image.png');

//       // Load image from asset
//       ByteData byteData = await rootBundle.load(imagePath);
//       Uint8List imageData = byteData.buffer.asUint8List();

//       // Upload the image data
//       UploadTask uploadTask = storageRef.putData(imageData);
//       TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
//       String downloadUrl = await snapshot.ref.getDownloadURL();

//       setState(() {
//         _downloadUrl = downloadUrl;
//       });

//       print('Image uploaded successfully. Download URL: $downloadUrl');
//     } catch (e) {
//       print('Failed to upload image: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Upload Asset Image to Firebase'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: uploadImage,
//               child: const Text('Upload Image'),
//             ),
//             if (_downloadUrl != null)
//               MyWidget(downloadUrl: _downloadUrl!),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class MyWidget extends StatelessWidget {
//   final String downloadUrl;
//   const MyWidget({super.key, required this.downloadUrl});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: QrImageView(
//         data: downloadUrl,  
//         version: QrVersions.auto,
//         size: 320,
//         gapless: false,
//         embeddedImageStyle: const QrEmbeddedImageStyle(
//           size: Size(80, 80),
//         ),
//       ),
//     );
//   }
// }
