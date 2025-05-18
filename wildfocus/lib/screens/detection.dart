import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:wildfocus/customs/customcolors.dart';

class DetectionScreen extends StatefulWidget {
  @override
  _DetectionScreenState createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen>
    with TickerProviderStateMixin {
  File? _image;
  String? _resultText;
  late Interpreter _interpreter;

  late List<String> _titleText;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _titleText = "Mantar Keşfi".split("");
    _controllers = _titleText
        .map((_) => AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 300),
            ))
        .toList();
    _fadeAnimations = _controllers
        .map((controller) =>
            Tween<double>(begin: 0.0, end: 1.0).animate(controller))
        .toList();

    _loadModel();
    _startAnimation();
  }

  void _startAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      _controllers[i].forward();
    }
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('mobilenet_model.tflite');
    } catch (e) {
      print("Model yüklenirken hata oluştu: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) return;
    }

    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    setState(() => _image = file);
    await _runModel(file);
  }

  Future<void> _runModel(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final resized = img.copyResize(image, width: 224, height: 224);

    // Model input shape: [1,224,224,3], float32 normalized [0-1]
    final input = Float32List(1 * 224 * 224 * 3);
    int index = 0;

 for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toDouble() / 255.0;
        final g = pixel.g.toDouble() / 255.0;
        final b = pixel.b.toDouble() / 255.0;

        input[index++] = r;
        input[index++] = g;
        input[index++] = b;
      }
    }

    // Output shape: [1,1]
    var output = List.filled(1, 0.0).reshape([1, 1]);

    _interpreter.run(input.reshape([1, 224, 224, 3]), output);

    final prediction = output[0][0] as double;

    final result = prediction < 0.5
        ? "🔴 Mantar zehirli olarak tahmin edildi"
        : "🟢 Mantar zehirsiz olarak tahmin edildi";

    setState(() {
      _resultText = result;
    });
  }

  void _pickImageFromCamera() => _pickImage(ImageSource.camera);
  void _pickImageFromGallery() => _pickImage(ImageSource.gallery);

  @override
  void dispose() {
    _interpreter.close();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: CustomColors.textfieldFill,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_titleText.length, (index) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: Text(
                _titleText[index],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.primaryText,
                ),
              ),
            );
          }),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (_image != null) ...[
              Image.file(_image!, height: 300),
              const SizedBox(height: 15),
              if (_resultText != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _resultText!.contains("zehirli")
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _resultText!,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _resultText!.contains("zehirli")
                          ? Colors.red
                          : Colors.green[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ] else ...[
              const Icon(Icons.image, size: 200),
              const SizedBox(height: 15),
              if (_resultText != null)
                Text(
                  _resultText!,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _resultText!.contains("zehirli")
                        ? Colors.red
                        : Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImageFromCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.button,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Kamera',
                    style: TextStyle(color: CustomColors.buttontext),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.button,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Galeri',
                    style: TextStyle(color: CustomColors.buttontext),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
