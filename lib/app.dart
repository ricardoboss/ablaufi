import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureProvider<EntriesRepository?>(
      initialData: null,
      create: (context) => EntriesRepository.load(),
      child: const MaterialApp(
        title: "Ablaufi",
        home: HomePage(),
      ),
    );
  }
}

class EntriesRepository {
  static Future<EntriesRepository> load() async {
    var storage = LocalStorage("ablaufi");
    var entries = storage.getItem("entries");
    if (entries is List) {
      if (entries.isEmpty) {
        return EntriesRepository(entries: <Entry>[]);
      }

      if (entries.first is Entry) {
        return EntriesRepository(entries: entries as List<Entry>);
      }
    }

    return EntriesRepository(entries: <Entry>[]);
  }

  final List<Entry> entries;

  EntriesRepository({required this.entries});
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rollerController;
  late final Animation _animation;

  @override
  void initState() {
    super.initState();

    _rollerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _animation = Tween<double>(
      begin: 0,
      end: pi / 2,
    ).animate(_rollerController);
  }

  @override
  void dispose() {
    super.dispose();

    _rollerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<EntriesRepository?>();
    if (repository == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    var fab = _RollingContainer(
      animation: _animation,
      child: FloatingActionButton(
        onPressed: () async {
          await _rollerController.forward(from: 0);

          var nameController = TextEditingController();
          DateTime? expiresAt;

          var result = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              content: Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Neuer Eintrag"),
                    TextField(controller: nameController),
                    TextButton(
                      onPressed: () async {
                        expiresAt = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 900)),
                        );
                      },
                      child: const Text("Set Date"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () {
                  Navigator.of(ctx).pop(true);
                }, child: const Text("Ok"))
              ],
            ),
          );

          if (result != null && result && expiresAt != null) {
            repository.entries.add(Entry(
              name: nameController.text,
              expiresAt: expiresAt!,
              addedAt: DateTime.now(),
            ));
          }

          await _rollerController.reverse(from: pi / 2);
        },
        child: const Icon(Icons.add),
      ),
    );

    return Scaffold(
      body: _HomeView(),
      floatingActionButton: fab,
    );
  }
}

class _RollingContainer extends StatelessWidget {
  final Animation animation;
  final Widget child;

  const _RollingContainer({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.rotate(
          angle: animation.value,
          child: child,
        );
      },
    );
  }
}

class Entry {
  final String name;
  final DateTime addedAt;
  final DateTime expiresAt;
  final File? picture;

  const Entry({
    required this.name,
    required this.addedAt,
    required this.expiresAt,
    this.picture,
  });

  String toJson() {
    return '{"name":"$name","addedAt":"${addedAt.toIso8601String()}","expiresAt":"${expiresAt.toIso8601String()}"}';
  }
}

class _HomeView extends StatefulWidget {
  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  @override
  Widget build(BuildContext context) {
    final repository = context.watch<EntriesRepository?>();
    if (repository == null) {
      throw ErrorDescription("Repository cannot be null in HomeView");
    }

    if (repository.entries.isEmpty) {
      return const Center(
        child: Text(
          "Kein Einträge vorhanden",
          style: TextStyle(color: Colors.black38),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      children: [
        for (var entry in repository.entries)
          GridTile(
            child: Text(entry.name),
          ),
      ],
    );
  }
}
