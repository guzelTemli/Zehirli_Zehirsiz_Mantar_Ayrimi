import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wildfocus/customs/customcolors.dart';

class DetectionScreen extends StatefulWidget {
  @override
  _DetectionScreenState createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> with TickerProviderStateMixin {
  File? _image;
  String? _speciesName;
  String? _probability;
  List<Map<String, dynamic>> _similarImages = [];
  String? _details;
  String? _isMushroom; // Mantar olup olmadığını belirten değişken
  bool _isLoading = false;

  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  final String _titleText = "Mantar Keşfi";

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      _titleText.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      ),
    );

    _fadeAnimations =
        _controllers
            .map(
              (controller) => Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeIn),
              ),
            )
            .toList();

    _playTitleAnimation();
  }

  void _playTitleAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 100));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final cameraPermission = await Permission.camera.request();
    if (!cameraPermission.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kamera izni verilmedi!')));
      return;
    }

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });
      await _identifySpecies(_image!);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });
      await _identifySpecies(_image!);
    }
  }

  Future<void> _identifySpecies(File image) async {
    final apiUrl = 'https://mushroom.kindwise.com/api/v1/identification';
    final apiKey = 'wildfocus'; // API key burada

    String base64Image = encodeImageToBase64(image.path);
    String dataUriImage = 'data:image/jpeg;base64,$base64Image';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Api-Key': apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'images': [dataUriImage],
        'latitude': 49.207,
        'longitude': 16.608,
        'similar_images': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Yanıtı yazdırarak ne geldiğini görmek faydalı olabilir
      print('API Yanıtı: $data');

      // Eğer classification ve suggestions varsa
      final suggestions = data['result']?['classification']?['suggestions'];

      if (suggestions != null && suggestions.isNotEmpty) {
        final firstSuggestion = suggestions[0];
        setState(() {
          _speciesName = firstSuggestion['name'] ?? 'Tür adı bulunamadı';
          _probability =
              firstSuggestion['probability']?.toString() ?? 'Belirsiz';
          _similarImages = List<Map<String, dynamic>>.from(firstSuggestion['similar_images'] ?? []);
          _details = firstSuggestion['description']?.toString() ?? 'Detay bulunamadı';
        });
      } else {
        setState(() {
          _speciesName = 'Herhangi bir öneri bulunamadı';
        });
      }

      // Mantar olup olmadığını kontrol etme
      final isMushroomData = data['result']?['is_mushroom'];
      if (isMushroomData != null) {
        setState(() {
          _isMushroom = isMushroomData['probability']?.toString() ?? 'Mantar değil';
        });
      } else {
        setState(() {
          _isMushroom = 'Mantar durumu belirlenemedi';
        });
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _speciesName = 'Tanımlama başarısız';
        _isLoading = false;
      });
    }
  }

  String encodeImageToBase64(String imagePath) {
    final imageBytes = File(imagePath).readAsBytesSync();
    return base64Encode(imageBytes);
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
            _image != null
                ? Image.file(_image!, height: 300)
                : Icon(Icons.image, size: 200),
            const SizedBox(height: 15),
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
            const SizedBox(height: 50),
            _isLoading
                ? CircularProgressIndicator()
                : _speciesName == null
                    ? Container()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mantar mı?: $_isMushroom',
                            style: TextStyle(
                                fontSize: 22, color: CustomColors.primaryText),
                          ),
                          Text(
                            'Tür Adı: $_speciesName',
                            style: TextStyle(
                              fontSize: 22,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          Text(
                            'Olasılık: $_probability',
                            style: TextStyle(
                              fontSize: 22,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          Text(
                            'Detaylar: $_details',
                            style: TextStyle(
                              fontSize: 22,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Benzer Görseller:',
                            style: TextStyle(
                              fontSize: 22,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _similarImages.isNotEmpty
                              ? SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _similarImages.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Image.network(
                                          _similarImages[index]['url'],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Text('Benzer görsel bulunamadı'),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}
