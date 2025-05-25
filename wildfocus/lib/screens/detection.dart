import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:wildfocus/customs/customcolors.dart';
import 'package:wildfocus/models/mushroom_detection.dart';

class DetectionScreen extends StatefulWidget {
  @override
  DetectionScreenState createState() => DetectionScreenState();
}

class DetectionScreenState extends State<DetectionScreen>
    with TickerProviderStateMixin {
  File? _image;
  String? _resultText;
  String? _speciesName;
  String? _probability;
  List<Map<String, dynamic>> _similarImages = [];
  String? _isMushroom; // Mantar olup olmadığını belirten değişken
  bool _isLoading = false;
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  Map<String, dynamic>? _mushroomDetails;

  late List<String> _titleText;
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _titleText = "Mantar Keşfi".split("");
    _controllers =
        _titleText
            .map(
              (_) => AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 300),
              ),
            )
            .toList();
    _fadeAnimations =
        _controllers
            .map(
              (controller) =>
                  Tween<double>(begin: 0.0, end: 1.0).animate(controller),
            )
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
      // Önce model dosyasının varlığını kontrol et
      final modelFile = await DefaultAssetBundle.of(
        context,
      ).load('assets/mobilenet_model.tflite');

      // Model yükleme seçeneklerini ayarla
      final interpreterOptions =
          InterpreterOptions()
            ..threads = 4
            ..useNnApiForAndroid = true;

      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenet_model.tflite',
        options: interpreterOptions,
      );

      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      setState(() {
        _isModelLoaded = false;
        _resultText =
            "Model yüklenirken bir hata oluştu. Lütfen uygulamayı yeniden başlatın.";
      });
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
    await _identifySpecies(file);
  }

  Future<void> _runModel(File imageFile) async {
    if (!_isModelLoaded || _interpreter == null) {
      setState(() {
        _resultText = "Model henüz yüklenmedi. Lütfen bekleyin.";
      });
      return;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return;

      // Giriş boyutlarını modelin beklediği şekilde ayarla
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final inputSize = inputShape[1]; // 224

      final resized = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Giriş tensörünü hazırla - 4 boyutlu olmalı [1, 224, 224, 3]
      final inputBuffer = Float32List(1 * inputSize * inputSize * 3);
      int index = 0;

      for (var y = 0; y < inputSize; y++) {
        for (var x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          // Normalize pixel değerlerini [0,1] aralığına
          inputBuffer[index++] = pixel.r / 255.0;
          inputBuffer[index++] = pixel.g / 255.0;
          inputBuffer[index++] = pixel.b / 255.0;
        }
      }

      // Giriş tensörünü 4 boyutlu hale getir
      final inputArray = inputBuffer.reshape([1, inputSize, inputSize, 3]);

      // Çıkış tensörünü hazırla - [1, 1] şeklinde olmalı
      final outputBuffer = Float32List(1 * 1).reshape([1, 1]);

      // Modeli çalıştır
      _interpreter!.run(inputArray, outputBuffer);

      // Sonucu işle
      final prediction = outputBuffer[0][0];

      final result =
          prediction < 0.5
              ? "🔴 Mantar zehirli olarak tahmin edildi"
              : "🟢 Mantar zehirsiz olarak tahmin edildi";

      setState(() {
        _resultText = result;
      });
    } catch (e) {
      setState(() {
        _resultText = "Tahmin yapılırken bir hata oluştu: $e";
      });
    }
  }

  Future<void> _identifySpecies(File image) async {
    final apiUrl =
        'https://mushroom.kindwise.com/api/v1/identification?details=common_names,gbif_id,taxonomy,rank,characteristic,edibility,psychoactive';
    final apiKey = 'API KEY';

    String base64Image = encodeImageToBase64(image.path);
    String dataUriImage = 'data:image/jpeg;base64,$base64Image';

    try {
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Eğer classification ve suggestions varsa
        final suggestions = data['result']?['classification']?['suggestions'];

        if (suggestions != null && suggestions.isNotEmpty) {
          final firstSuggestion = suggestions[0];
          setState(() {
            _speciesName = firstSuggestion['name'] ?? 'Tür adı bulunamadı';
            _probability =
                firstSuggestion['probability']?.toString() ?? 'Belirsiz';
            _similarImages = List<Map<String, dynamic>>.from(
              firstSuggestion['similar_images'] ?? [],
            );

            // Modal Sheet için detaylar
            if (firstSuggestion['details'] != null) {
              _mushroomDetails = firstSuggestion['details'];
            }
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
            _isMushroom =
                isMushroomData['probability']?.toString() ?? 'Mantar değil';
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
    } catch (e) {
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

  void _pickImageFromCamera() => _pickImage(ImageSource.camera);
  void _pickImageFromGallery() => _pickImage(ImageSource.gallery);

  void _showDetailsModal() {
    if (_mushroomDetails == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: CustomColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CustomColors.textfieldFill,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mantar Detayları',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CustomColors.primaryText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: CustomColors.primaryText,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_mushroomDetails!['common_names'] != null) ...[
                          const Text(
                            'Yaygın İsimler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_mushroomDetails!['common_names'] as List).join(
                              ', ',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_mushroomDetails!['taxonomy'] != null) ...[
                          const Text(
                            'Taksonomi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_mushroomDetails!['taxonomy']
                                  as Map<String, dynamic>)
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: CustomColors.primaryText,
                                    ),
                                  ),
                                ),
                              ),
                          const SizedBox(height: 16),
                        ],
                        if (_mushroomDetails!['characteristic'] != null) ...[
                          const Text(
                            'Özellikler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...(_mushroomDetails!['characteristic']
                                  as Map<String, dynamic>)
                              .entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: CustomColors.primaryText,
                                    ),
                                  ),
                                ),
                              ),
                          const SizedBox(height: 16),
                        ],
                        if (_mushroomDetails!['edibility'] != null) ...[
                          const Text(
                            'Yenilebilirlik',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mushroomDetails!['edibility'].toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_mushroomDetails!['psychoactive'] != null) ...[
                          const Text(
                            'Psikoaktif',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mushroomDetails!['psychoactive']
                                ? 'Evet'
                                : 'Hayır',
                            style: const TextStyle(
                              fontSize: 16,
                              color: CustomColors.primaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
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
        automaticallyImplyLeading: true,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  icon: Icon(Icons.arrow_back, color: CustomColors.primaryText),
                  onPressed: () => Navigator.of(context).pop(),
                )
                : null,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (_image != null) ...[
                    Image.file(_image!, height: 300),
                    const SizedBox(height: 15),
                  ] else ...[
                    const Icon(Icons.image, size: 200),
                    const SizedBox(height: 15),
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
                  if (_resultText != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            _resultText!.contains("zehirli")
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _resultText!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              _resultText!.contains("zehirli")
                                  ? Colors.red
                                  : Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_resultText != null)
                    Column(
                      children: [
                        Text(
                          'Mantar mı?: ${_isMushroom != null && double.tryParse(_isMushroom!) != null ? '%${(double.parse(_isMushroom!) * 100).toStringAsFixed(1)}' : (_isMushroom ?? '')}',
                          style: TextStyle(
                            fontSize: 22,
                            color: CustomColors.primaryText,
                          ),
                        ),
                        Text(
                          'Tür Adı: $_speciesName',
                          style: TextStyle(
                            fontSize: 22,
                            color: CustomColors.primaryText,
                          ),
                        ),
                        Text(
                          'Olasılık: ${_probability != null && double.tryParse(_probability!) != null ? '%${(double.parse(_probability!) * 100).toStringAsFixed(1)}' : (_probability ?? '')}',
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
                                    padding: const EdgeInsets.only(right: 10),
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
                        const SizedBox(height: 20),
                        if (_mushroomDetails != null)
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _showDetailsModal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: CustomColors.button,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      'Detayları Gör',
                                      style: TextStyle(
                                        color: CustomColors.buttontext,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        (_speciesName != null && _image != null)
                                            ? () async {
                                              final now = DateTime.now();
                                              final detection = MushroomDetection(
                                                name: _speciesName!,
                                                date:
                                                    "${now.day}.${now.month}.${now.year}  ${now.hour}:${now.minute}",
                                                isPoisonous: _resultText!
                                                    .contains("zehirli"),
                                                imageUrl: _image!.path,
                                                probability: _probability,
                                                isMushroom: _isMushroom,
                                                similarImages:
                                                    _similarImages
                                                        .map(
                                                          (e) =>
                                                              e['url']
                                                                  as String,
                                                        )
                                                        .toList(),
                                                details: _mushroomDetails,
                                              );
                                              await MushroomDetection.saveToCollection(
                                                detection,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Koleksiyona eklendi!',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                            : null,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Koleksiyona Ekle'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: CustomColors.button,
                                      foregroundColor: CustomColors.buttontext,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
