// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, sized_box_for_whitespace, avoid_print

import 'dart:convert';
// ignore: unused_import
import 'dart:js';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => NoteProvider(),
      child: MyNoteApp(),
    ),
  );
}

class MyNoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de records',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NoteListScreen(),
    );
  }
}

class NoteListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('App de records')),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: NoteListView(),
        ),
      ),
      //Boton que te manda a la pagina de agregar notas
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNoteScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

//Vista principal de notas
class NoteListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, child) {
        //Lista con todas las notas
        List<Note> notes = provider.getNotes();
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(notes[index].title),
                subtitle: Text(notes[index].content),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditNoteScreen(noteIndex: index),
                    ),
                  ).then((editedNote) {
                    if (editedNote != null) {
                      provider.editNote(index, editedNote);
                    }
                  });
                },
                //Al Mantener pulsado te manda lo de borrar
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Eliminar Nota"),
                        content: Text("Segur que vols eliminar aquesta nota?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel·lar"),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deleteNote(index);
                              Navigator.pop(context);
                            },
                            child: Text("Eliminar"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

//
class NoteProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  static const String _key = 'notes';

  List<Note> _notes = [];

  NoteProvider() {
    _loadNotes();
  }

  List<Note> getNotes() => _notes;

  void addNote(Note note) {
    _notes.add(note);
    _saveNotes();
    notifyListeners();
  }

  void editNote(int index, Note editedNote) {
    _notes[index] = editedNote;
    _saveNotes();
    notifyListeners();
  }

  void deleteNote(int index) {
    _notes.removeAt(index);
    _saveNotes();
    notifyListeners();
  }

  void _loadNotes() async {
    _prefs = await SharedPreferences.getInstance();
    String notesString = _prefs.getString(_key) ?? '[]';
    List<dynamic> notesJson = jsonDecode(notesString);
    _notes = notesJson.map((note) => Note.fromJson(note)).toList();
    notifyListeners();
  }

  void _saveNotes() {
    List<Map<String, dynamic>> notesJson = _notes.map((note) => note.toJson()).toList();
    _prefs.setString(_key, jsonEncode(notesJson));
  }
}

//Pantalla de agregar nota
class AddNoteScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Afegir Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Títol'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Contingut'),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final provider = Provider.of<NoteProvider>(context, listen: false);
                provider.addNote(
                  Note(
                    title: titleController.text,
                    content: contentController.text,
                  ),
                );
                Navigator.pop(context); // Cerrar la pantalla de añadir nota
              },
              child: Text('Afegir Nota'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditNoteScreen extends StatelessWidget {
  final int noteIndex;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  EditNoteScreen({required this.noteIndex});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context, listen: false);

     final note = provider.getNotes()[noteIndex];
    titleController.text = note.title;
    contentController.text = note.content;

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          //Campos del edit note
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Títol'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(labelText: 'Contingut'),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.editNote(
                  noteIndex,
                  Note(
                    title: titleController.text,
                    content: contentController.text,
                  ),
                );
                Navigator.pop(context); // Volver a la pantalla anterior
              },
              child: Text('Guardar Canvis'),
            ),
           ElevatedButton(
  onPressed: () {
    //Alerta de estas seguro
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Nota"),
          content: Text("Segur que vols eliminar aquesta nota?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),//Para volver a la pag anterior
              child: Text("Cancel·lar"),
            ),
            TextButton(
              onPressed: () {
                provider.deleteNote(noteIndex);
                Navigator.popUntil(context, ModalRoute.withName('/')); // Regresar a la vista principal
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  },
  child: Text('Eliminar Nota'),
),

          ],
        ),
      ),
    );
  }
}


//Clase nota
class Note {
  final String title;
  final String content;

  Note({required this.title, required this.content});

  Map<String, dynamic> toJson() {
    return {'title': title, 'content': content};
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'],
      content: json['content'],
    );
  }
}
