import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:scoped_model/scoped_model.dart';
import './models/recognizer_model.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

enum TtsState { playing, stopped }

RecognizerModel model = RecognizerModel();

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TtsState ttsState = TtsState.stopped;

  FlutterTts flutterTts = new FlutterTts();

  String recognizedText = "Loading ...";
  File pickedImage;
  bool isImageLoaded = false;
  String w = "";

  Future pickImage() async {
    var tempStore = await ImagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      pickedImage = tempStore;
      isImageLoaded = true;
      readText();
      getImageData();
    });
  }

  String productData = "";
  Future getImageData() async {
    if (isImageLoaded == true) {
      model.isRecognizing
          ? CircularProgressIndicator()
          : showModalBottomSheet(
              context: context,
              builder: (BuildContext ctx) {
                return FutureBuilder(
                    future: model.classifyImage(pickedImage),
                    builder: (BuildContext fCtx, AsyncSnapshot<List> snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.data.isEmpty) {
                          return Center(child: Text("Cannot recognize Image"));
                        } else {
                          return ListView.separated(
                              physics: ClampingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              separatorBuilder: (sCtx, pos) => Divider(
                                    height: 2.0,
                                  ),
                              itemCount: snapshot.data.length,
                              itemBuilder: (lCtx, pos) {
                                productData =
                                    snapshot.data[pos]['detectedClass'];
                                return Material(
                                  child: ListTile(
                                    title: Text(
                                        snapshot.data[pos]['detectedClass']),
                                    trailing: Text((snapshot.data[pos]
                                                    ['confidenceInClass'] *
                                                100)
                                            .toString() +
                                        "%"),
                                  ),
                                );
                              });
                        }
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text("There's some problem, Please try again"),
                        );
                      }
                      return CircularProgressIndicator();
                    });
              });
    }
  }

  Future _speak() async {
    print(recognizedText.toString().length);
    var result = await flutterTts.speak(recognizedText);
    if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  String words = "Random words";
  Future readText() async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);

    for (TextBlock block in readText.blocks) {
//      for (TextLine line in block.lines) {
//        for (TextElement word in line.elements) {
//          w = w + " "+ block.text;
      print(block.text);

      words = block.text;
    }
//      }
//    }

    @override
    void dispose() {
      super.dispose();
      flutterTts.stop();
    }

    if (this.mounted) {
      setState(() {
        recognizedText = words;
        _speak();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accesibilify"),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: 20.0),
          isImageLoaded
              ? Center(
                  child: Container(
                    padding: EdgeInsets.all(30),
                    height: 200.0,
                    width: 200.0,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: FileImage(pickedImage), fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              : Container(),
          SizedBox(height: 10.0),
          FlatButton(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Text("Pick an image"),
            textColor: Colors.white,
            color: Colors.deepPurpleAccent,
            onPressed: pickImage,
          ),
          SizedBox(height: 10.0),
          FlatButton(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Text("Read Text"),
            textColor: Colors.white,
            color: Colors.deepPurpleAccent,
            onPressed: () {
              print("speak");
            },
          ),
          Container(
            child: Text("" + w),
          ),
          Container(
            child: Text(productData),
          )
        ],
      ),
    );
  }
}
