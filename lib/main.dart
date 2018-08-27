import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

//uses english words library from dart to generate a simple
//instagram caption. The list is scrolls, and saved items
//show up on a seperate "saved page"

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Instagram Captions Generator',
      theme: new ThemeData(
          primaryColor: Colors.pinkAccent,
      ),
      home: new RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  createState() => new RandomWordsState();
}

class RandomWordsState extends State<RandomWords> {
  @override
  final _suggestions = <String>[];
  final _saved = new Set<String>();
  final _biggerFont = const TextStyle(fontSize: 18.0);

  Widget build(BuildContext context) {
    return new Scaffold (
      appBar: new AppBar(
        title: new Text('Instagram Captions Generator'),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.list), onPressed: _pushSaved,),
          new IconButton(icon: new Icon(Icons.photo), onPressed: buildImage)
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return new ListView.builder(
        padding: const EdgeInsets.all(16.0),

        itemBuilder: (context, i) {
          if (i.isOdd) return new Divider();

          final index = i ~/ 2;

          //"noun" and "adj" hold 10 strings, so this loop
          //combines the 10 together for a simple caption
          if (index >= _suggestions.length) {
            final cap = new Set<String>();

            Iterable noun = nouns.take(50);
            Iterable adj = adjectives.take(50);
            Iterator<String> nit = noun.iterator;
            Iterator<String> adjit = adj.iterator;

            while (nit.moveNext() && adjit.moveNext()) {
              String s = adjit.current + " " + nit.current;
              cap.add(s);
            }

            _suggestions.addAll(cap);
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

  //builds a ListTile (which is a row with a fixed height)
  Widget _buildRow(String pair) {
    final alreadySaved = _saved.contains(pair);
    return new ListTile(
      title: new Text (
        pair,
        style: _biggerFont,
      ),
      trailing: new Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.pink : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          final tiles = _saved.map(
                (pair) {
              return new ListTile(
                  title: new Text(
                    pair,
                    style: _biggerFont,
                  )
              );
            },
          );
          final divided = ListTile.divideTiles(context: context, tiles: tiles,)
              .toList();
          return new Scaffold(
            appBar: new AppBar(title: new Text('Saved Captions'),),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  void buildImage() {
    File _image;
    String caption;

    Future getLabels() async {
      final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(_image);
      final LabelDetector labelDetector = FirebaseVision.instance.labelDetector();
      final List<Label> labels = await labelDetector.detectInImage(visionImage);

      for (Label label in labels) {
        final String text = label.label;
        final String entityId = label.entityId;
        caption = text+entityId;
      }
    }

    void getImage() async {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);

      setState(() {
        _image = image;
      });
    }

    Navigator.of(context).push(
        new MaterialPageRoute(
            builder: (context) {
          return new Scaffold(
            appBar: new AppBar(
              title: new Text('Image- Based Caption'),
            ),
            body: new Center(

              heightFactor: 20.0,
              widthFactor: 15.0,
              child:
              _image == null ? new Text('No image selected') :
              new Image.file(_image,width: 200.0,height: 200.0,),
            ),

            //display caption here
            
            floatingActionButton: new FloatingActionButton(
              onPressed: getImage,
              tooltip: 'Pick Image',
              child: new Icon(Icons.add_a_photo),
            ),
            bottomNavigationBar: new Text(caption),

          );
            }
        )
    );
  }

}
