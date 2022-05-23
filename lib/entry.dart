import 'dart:convert';
import 'dart:io';

import 'package:ablaufi/emptyentry.dart';
import 'package:flutter/foundation.dart';

class Entry with ChangeNotifier {
  String _name;
  DateTime _addedAt;
  DateTime _expiresAt;
  File? _picture;

  String get name => _name;
  DateTime get addedAt => _addedAt;
  DateTime get expiresAt => _expiresAt;
  File? get picture => _picture;

  set name(String name) {
    _name = name;

    notifyListeners();
  }

  set addedAt(DateTime addedAt) {
    _addedAt = addedAt;

    notifyListeners();
  }

  set expiresAt(DateTime expiresAt) {
    _expiresAt = expiresAt;

    notifyListeners();
  }

  set picture(File? picture) {
    _picture = picture;

    notifyListeners();
  }

  Entry(
    this._name,
    this._addedAt,
    this._expiresAt,
    this._picture,
  );

  static Entry fromJson(String json) {
    final Map<String, dynamic> map = jsonDecode(json);
    return Entry(
      map['name'] as String,
      DateTime.parse(map['addedAt'] as String),
      DateTime.parse(map['expiresAt'] as String),
      map['picture'] != null ? File(map['picture'] as String) : null,
    );
  }

  String toJson() {
    final Map<String, dynamic> map = <String, dynamic>{
      'name': name,
      'addedAt': addedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };

    if (picture != null) {
      map['picture'] = picture!.path;
    }

    return jsonEncode(map);
  }

  EmptyEntry toEmptyEntry() {
    return EmptyEntry(
      name,
      expiresAt,
      addedAt,
      picture,
    );
  }

  updateFrom(EmptyEntry entry) {
    if (entry.name != null) {
      name = entry.name!;
    }

    if (entry.expiresAt != null) {
      expiresAt = entry.expiresAt!;
    }

    if (entry.addedAt != null) {
      addedAt = entry.addedAt!;
    }

    if (entry.picture != null) {
      picture = entry.picture!;
    }

    notifyListeners();
  }
}
