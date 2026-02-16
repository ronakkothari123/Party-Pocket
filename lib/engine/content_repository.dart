import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class ContentRepository {
  static final ContentRepository _instance = ContentRepository._();
  factory ContentRepository() => _instance;
  ContentRepository._();

  List<dynamic>? _headsUp;
  List<dynamic>? _tenQuestions;
  List<dynamic>? _chameleon;
  List<dynamic>? _hotPotato;
  List<dynamic>? _wavelength;

  final _rand = Random();

  Future<void> preload() async {
    final results = await Future.wait([
      rootBundle.loadString('assets/content/heads_up.json'),
      rootBundle.loadString('assets/content/ten_questions.json'),
      rootBundle.loadString('assets/content/chameleon.json'),
      rootBundle.loadString('assets/content/hot_potato.json'),
      rootBundle.loadString('assets/content/wavelength.json'),
    ]);
    _headsUp = jsonDecode(results[0]) as List;
    _tenQuestions = jsonDecode(results[1]) as List;
    _chameleon = jsonDecode(results[2]) as List;
    _hotPotato = jsonDecode(results[3]) as List;
    _wavelength = jsonDecode(results[4]) as List;
  }

  List<String> getHeadsUpWords({bool kidSafe = false, int count = 40}) {
    final pool = _headsUp ?? [];
    List<dynamic> filtered;
    if (kidSafe) {
      filtered = pool.where((w) => w['kidSafe'] == true).toList();
    } else {
      filtered = List.from(pool);
    }
    filtered.shuffle(_rand);
    return filtered
        .take(count)
        .map<String>((w) => w['word'] as String)
        .toList();
  }

  Map<String, dynamic> getTenQuestionsTarget({bool kidSafe = false}) {
    final pool = _tenQuestions ?? [];
    List<dynamic> filtered;
    if (kidSafe) {
      filtered = pool.where((w) => w['kidSafe'] == true).toList();
    } else {
      filtered = List.from(pool);
    }
    filtered.shuffle(_rand);
    return Map<String, dynamic>.from(filtered.first);
  }

  /// Returns {category, secretWord, words}
  Map<String, dynamic> getChameleonCard() {
    final pool = _chameleon ?? [];
    final card = pool[_rand.nextInt(pool.length)];
    final words = List<String>.from(card['words'] as List);
    final secretWord = words[_rand.nextInt(words.length)];
    return {
      'category': card['category'] as String,
      'secretWord': secretWord,
      'words': words,
    };
  }

  String getHotPotatoCategory() {
    final pool = _hotPotato ?? [];
    return pool[_rand.nextInt(pool.length)]['category'] as String;
  }

  String getWavelengthPrompt() {
    final pool = _wavelength ?? [];
    return pool[_rand.nextInt(pool.length)]['prompt'] as String;
  }

  List<String> getWavelengthPrompts({int count = 3}) {
    final pool = _wavelength ?? [];
    final shuffled = List<dynamic>.from(pool)..shuffle(_rand);
    return shuffled.take(count).map<String>((p) => p['prompt'] as String).toList();
  }

  /// Get distractor words for ten questions multiple choice
  List<String> getTenQuestionsDistractors(String correct, {int count = 3}) {
    final pool = _tenQuestions ?? [];
    final others = pool
        .where((w) => w['word'] != correct)
        .map<String>((w) => w['word'] as String)
        .toList();
    others.shuffle(_rand);
    return others.take(count).toList();
  }
}
