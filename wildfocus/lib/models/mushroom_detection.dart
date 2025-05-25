import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MushroomDetection {
  final String name;
  final String date;
  final bool isPoisonous;
  final String? imageUrl;
  final String? probability;
  final String? isMushroom;
  final List<String>? similarImages;
  final Map<String, dynamic>? details;

  MushroomDetection({
    required this.name,
    required this.date,
    required this.isPoisonous,
    this.imageUrl,
    this.probability,
    this.isMushroom,
    this.similarImages,
    this.details,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date,
    'isPoisonous': isPoisonous,
    'imageUrl': imageUrl,
    'probability': probability,
    'isMushroom': isMushroom,
    'similarImages': similarImages,
    'details': details,
  };

  factory MushroomDetection.fromJson(Map<String, dynamic> json) =>
      MushroomDetection(
        name: json['name'],
        date: json['date'],
        isPoisonous: json['isPoisonous'],
        imageUrl: json['imageUrl'],
        probability: json['probability'],
        isMushroom: json['isMushroom'],
        similarImages:
            json['similarImages'] == null
                ? null
                : List<String>.from(json['similarImages']),
        details:
            json['details'] == null
                ? null
                : Map<String, dynamic>.from(json['details']),
      );

  static List<MushroomDetection> listFromJson(String jsonString) {
    final List<dynamic> decoded = json.decode(jsonString);
    return decoded.map((e) => MushroomDetection.fromJson(e)).toList();
  }

  static String listToJson(List<MushroomDetection> list) {
    return json.encode(list.map((e) => e.toJson()).toList());
  }

  // SharedPreferences helpers
  static const String collectionKey = 'mushroom_collection';

  static Future<void> saveToCollection(MushroomDetection detection) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(collectionKey);
    List<MushroomDetection> list =
        existing != null ? MushroomDetection.listFromJson(existing) : [];
    list.add(detection);
    await prefs.setString(collectionKey, MushroomDetection.listToJson(list));
  }

  static Future<List<MushroomDetection>> loadCollection() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(collectionKey);
    if (existing == null) return [];
    return MushroomDetection.listFromJson(existing);
  }
}
