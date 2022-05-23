import 'dart:io';
import 'dart:math';

import 'package:ablaufi/emptyentry.dart';
import 'package:ablaufi/entry.dart';
import 'package:ablaufi/entrypoolpersister.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ablaufi/entrypool.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Ablaufi",
      home: HomePage(),
    );
  }
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
    return FutureBuilder(
      future: EntryPool.loadFromLocalStorage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          final _pool = snapshot.data as EntryPool;
          final _persister = EntryPoolPersister(pool: _pool);

          _pool.addListener(_persister.onPoolUpdated);

          return Scaffold(
            floatingActionButton: _RollingContainer(
              animation: _animation,
              child: FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () async {
                  await _rollerController.forward(from: 0);

                  var result = await showDialog<EmptyEntry?>(
                    context: context,
                    builder: (ctx) => _EntryEditor(entry: EmptyEntry()),
                  );

                  if (result != null) {
                    _pool.add(result.toEntry());
                  }

                  await _rollerController.reverse(from: pi / 2);
                },
              ),
            ),
            body: ChangeNotifierProvider.value(
              value: _pool,
              child: Consumer<EntryPool>(
                builder: (context, pool, _) {
                  if (pool.entries.isEmpty) {
                    return const Center(
                      child: Text("Keine Einträge"),
                    );
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (var entry in pool.entries)
                        ChangeNotifierProvider<Entry>.value(
                          value: entry,
                          child: Consumer<Entry>(
                            builder: (c, e, _) => Card(
                              semanticContainer: true,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              borderOnForeground: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  var result = await showDialog(
                                    context: context,
                                    builder: (context) =>
                                        _EntryEditor(entry: e.toEmptyEntry()),
                                  );

                                  if (result == false) {
                                    pool.remove(e);
                                  } else if (result != null) {
                                    e.updateFrom(result);

                                    await _persister.onEntryUpdated();
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    image: e.picture != null
                                        ? DecorationImage(
                                            image: Image.file(e.picture!).image,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    border: Border.all(
                                      color: e.expiresAt.isAfter(DateTime.now()
                                              .add(const Duration(days: 30)))
                                          ? Colors.white
                                          : (e.expiresAt.isAfter(DateTime.now()
                                                  .add(const Duration(days: 7)))
                                              ? Colors.green
                                              : (e.expiresAt.isAfter(
                                                      DateTime.now().add(
                                                          const Duration(
                                                              days: 3)))
                                                  ? Colors.amber
                                                  : Colors.red)),
                                      width: 16,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4.0),
                                  child: Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Card(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            child: Center(child: Text(e.name, style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16.0),))),
                                        Card(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            child: Center(
                                                child: Text(
                                                    "${e.expiresAt.day}.${e.expiresAt.month}.${e.expiresAt.year}", style: DefaultTextStyle.of(context).style.copyWith(fontSize: 20.0),))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        }
      },
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

class _EntryEditor extends StatefulWidget {
  final EmptyEntry entry;

  const _EntryEditor({Key? key, required this.entry}) : super(key: key);

  @override
  State<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<_EntryEditor> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  DateTime? _expiresAt;
  File? _picture;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.entry.name ?? "";
    _expiresAt = widget.entry.expiresAt;
    _picture = widget.entry.picture;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController),
          TextButton(
            child: Text(_expiresAt == null
                ? "Läuft ab am..."
                : "Läuft ab am ${_expiresAt!.day}.${_expiresAt!.month}.${_expiresAt!.year}"),
            onPressed: () async {
              var date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(
                  const Duration(days: 900),
                ),
              );

              setState(() {
                _expiresAt = date;
              });
            },
          ),
          GestureDetector(
            child: _picture == null
                ? const Icon(Icons.add_a_photo)
                : Image.file(_picture!),
            onTap: () async {
              var picture = await _picker.pickImage(source: ImageSource.camera);
              if (picture != null) {
                setState(() {
                  _picture = File(picture.path);
                });
              }
            },
          ),
        ],
      ),
      actions: [
        if (widget.entry.addedAt != null)
          TextButton(
            child: const Icon(Icons.delete_forever),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        TextButton(
          child: const Icon(Icons.check),
          onPressed: () {
            Navigator.of(context).pop(
              EmptyEntry(
                _nameController.text,
                _expiresAt,
                widget.entry.addedAt,
                _picture,
              ),
            );
          },
        ),
      ],
    );
  }
}
