import 'package:flutter/material.dart';
import 'package:wildfocus/customs/customcolors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wildfocus/models/mushroom_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<MushroomDetection> _collection = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    final list = await MushroomDetection.loadCollection();
    setState(() {
      _collection = list.reversed.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.background,
      appBar: AppBar(
        backgroundColor: CustomColors.textfieldFill,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Koleksiyonum',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CustomColors.primaryText,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CustomColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _collection.isEmpty
              ? const Center(child: Text('Henüz koleksiyonunuzda mantar yok.'))
              : SafeArea(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _collection.length,
                  itemBuilder: (context, index) {
                    final item = _collection[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    MushroomDetailScreen(mushroom: item),
                          ),
                        );
                        _loadCollection();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: CustomColors.textfieldFill,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading:
                              item.imageUrl != null &&
                                      item.imageUrl!.isNotEmpty &&
                                      item.imageUrl!.startsWith('/')
                                  ? SafeImageFile(
                                    path: item.imageUrl!,
                                    width: 60,
                                    height: 60,
                                  )
                                  : (item.imageUrl != null &&
                                          item.imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          item.imageUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      )),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CustomColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

class MushroomDetailScreen extends StatelessWidget {
  final MushroomDetection mushroom;
  const MushroomDetailScreen({required this.mushroom, super.key});

  void _deleteMushroom(BuildContext context) async {
    final list = await MushroomDetection.loadCollection();
    final updated = List<MushroomDetection>.from(list)..removeWhere(
      (item) =>
          item.name == mushroom.name &&
          item.date == mushroom.date &&
          item.isPoisonous == mushroom.isPoisonous,
    );
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        MushroomDetection.collectionKey,
        MushroomDetection.listToJson(updated),
      );
    });
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Koleksiyondan silindi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.background,
      appBar: AppBar(
        backgroundColor: CustomColors.textfieldFill,
        elevation: 0,
        centerTitle: true,
        title: Text(
          mushroom.name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CustomColors.primaryText,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CustomColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteMushroom(context),
            tooltip: 'Sil',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 40,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (mushroom.imageUrl != null &&
                  mushroom.imageUrl!.isNotEmpty &&
                  mushroom.imageUrl!.startsWith('/'))
                Center(
                  child: SafeImageFile(
                    path: mushroom.imageUrl!,
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 200,
                    borderRadius: 16,
                  ),
                )
              else if (mushroom.imageUrl != null &&
                  mushroom.imageUrl!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      mushroom.imageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey, size: 80),
                ),
              const SizedBox(height: 24),
              Text(
                'Tespit Tarihi: ${mushroom.date}',
                style: TextStyle(fontSize: 18, color: CustomColors.primaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                mushroom.isPoisonous ? 'Zehirli' : 'Zehirsiz',
                style: TextStyle(
                  fontSize: 18,
                  color: mushroom.isPoisonous ? Colors.red : Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (mushroom.probability != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Olasılık: %${(double.tryParse(mushroom.probability ?? '') != null ? (double.parse(mushroom.probability!) * 100).toStringAsFixed(1) : mushroom.probability ?? '-')}',
                  style: TextStyle(
                    fontSize: 18,
                    color: CustomColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (mushroom.isMushroom != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Mantar mı?: %${(double.tryParse(mushroom.isMushroom ?? '') != null ? (double.parse(mushroom.isMushroom!) * 100).toStringAsFixed(1) : mushroom.isMushroom ?? '-')}',
                  style: TextStyle(
                    fontSize: 18,
                    color: CustomColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (mushroom.similarImages != null &&
                  mushroom.similarImages!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Benzer Görseller:',
                  style: TextStyle(
                    fontSize: 18,
                    color: CustomColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: mushroom.similarImages!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Image.network(
                          mushroom.similarImages![index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (mushroom.details != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Detaylar:',
                  style: TextStyle(
                    fontSize: 18,
                    color: CustomColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                _buildDetails(mushroom.details!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Map<String, dynamic> details) {
    List<Widget> widgets = [];
    if (details['common_names'] != null) {
      widgets.add(
        Text(
          'Yaygın İsimler: ${(details['common_names'] as List).join(", ")}',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    if (details['taxonomy'] != null) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        const Text('Taksonomi:', style: TextStyle(fontWeight: FontWeight.bold)),
      );
      (details['taxonomy'] as Map<String, dynamic>).forEach((k, v) {
        widgets.add(Text('$k: $v', style: const TextStyle(fontSize: 15)));
      });
    }
    if (details['characteristic'] != null) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        const Text(
          'Özellikler:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      (details['characteristic'] as Map<String, dynamic>).forEach((k, v) {
        widgets.add(Text('$k: $v', style: const TextStyle(fontSize: 15)));
      });
    }
    if (details['edibility'] != null) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Text(
          'Yenilebilirlik: ${details['edibility']}',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    if (details['psychoactive'] != null) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Text(
          'Psikoaktif: ${details['psychoactive'] ? 'Evet' : 'Hayır'}',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class SafeImageFile extends StatelessWidget {
  final String path;
  final double width;
  final double height;
  final double borderRadius;
  const SafeImageFile({
    required this.path,
    required this.width,
    required this.height,
    this.borderRadius = 10,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data == true) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          );
        } else {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          );
        }
      },
    );
  }
}
