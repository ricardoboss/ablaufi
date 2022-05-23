import 'dart:convert';

import 'package:ablaufi/entry.dart';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';

class EntryPool with ChangeNotifier {
  final List<Entry> _entries;

  EntryPool(this._entries);

  void add(Entry entry) {
    _entries.add(entry);

    notifyListeners();
  }

  void remove(Entry entry) {
    _entries.remove(entry);

    notifyListeners();
  }

  void clear() {
    _entries.clear();

    notifyListeners();
  }

  List<Entry> get entries => _entries;

  static Future<EntryPool> loadFromLocalStorage() async {
    final storage = LocalStorage('ablaufi');
    await storage.ready;
    final entries = await storage.getItem('entries');
    if (entries != null) {
      return EntryPool.fromJson(entries);
    } else {
      return EntryPool([]);
    }
  }

  Future<void> saveToLocalStorage() async {
    final storage = LocalStorage('ablaufi');
    await storage.ready;
    await storage.setItem('entries', this);
  }

  String toJson() {
    return jsonEncode(_entries, toEncodable: (e) => (e as Entry).toJson());
  }

  static EntryPool fromJson(String json) {
     List<dynamic> entryList = jsonDecode(json);
     List<Entry> entries = [];
     for (var entry in entryList) {
       entries.add(Entry.fromJson(entry));
     }

     return EntryPool(entries);
  }
}
