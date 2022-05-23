import 'package:ablaufi/entrypool.dart';

class EntryPoolPersister {
  final EntryPool pool;
  int _lastSavedCount = 0;

  EntryPoolPersister({required this.pool}) {
    _lastSavedCount = pool.entries.length;
  }

  Future<void> onPoolUpdated() async {
    if (pool.entries.length != _lastSavedCount) {
      _lastSavedCount = pool.entries.length;
      await pool.saveToLocalStorage();
    }
  }

  Future<void> onEntryUpdated() async {
    await pool.saveToLocalStorage();
  }
}
