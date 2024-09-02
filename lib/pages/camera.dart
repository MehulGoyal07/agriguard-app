import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'dart:typed_data';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    Tflite.close();
    super.dispose();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: 'assets/plants.tflite',
      labels: 'assets/labels.txt', // If you have a labels file
    );
  }

  Future<void> captureAndAnalyzeImage() async {
    try {
      await _initializeControllerFuture;

      // Capture the image
      final image = await _controller!.takePicture();

      // Pass the image to the model
      var output = await analyzeImage(image.path);

      // Navigate to the result page with the analysis result
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(disease: output),
        ),
      );
    } catch (e) {
      print('Error capturing or analyzing image: $e');
    }
  }

  Future<String> analyzeImage(String imagePath) async {
    var recognitions = await Tflite.runModelOnImage(
      path: imagePath,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 1,
      threshold: 0.5,
    );

    if (recognitions != null && recognitions.isNotEmpty) {
      return recognitions.first['label'];
    } else {
      return "Disease not detected";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Screen'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller!);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: captureAndAnalyzeImage,
        child: Icon(Icons.camera),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String disease;

  ResultScreen({required this.disease});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disease Detection Result'),
      ),
      body: Center(
        child: Text(
          'Detected Disease: $disease',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
