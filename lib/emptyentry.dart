import 'dart:io';

import 'package:ablaufi/entry.dart';

class EmptyEntry {
  String? name;
  DateTime? expiresAt;
  DateTime? addedAt;
  File? picture;

  EmptyEntry([
    this.name,
    this.expiresAt,
    this.addedAt,
    this.picture,
  ]);

  Entry toEntry() {
    if (name == null) {
      throw ArgumentError('name cannot be null');
    }

    if (expiresAt == null) {
      throw ArgumentError('expiresAt cannot be null');
    }

    return Entry(
      name!,
      addedAt ?? DateTime.now(),
      expiresAt!,
      picture,
    );
  }
}
