import 'dart:io';

import 'package:scoped_model/scoped_model.dart';
import 'package:tflite/tflite.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

enum CameraMode {
  FRONT,
  BACK
}

class RecognizerModel extends Model {
  String model;
  CameraController cameraController;
  List<CameraDescription> cameras;
  Directory baseDir;
  bool isRecognizing = false;

  Future<Directory> get imagePath async {
    baseDir = await getExternalStorageDirectory();
    return baseDir;
  }

  getCameras() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await cameraController.initialize();
    notifyListeners();
  }

  void dispose() {
    cameraController.dispose();
  }

  void loadModel() async {
    model = await Tflite.loadModel(
        model: 'assets/model.tflite',
        labels: 'assets/objects.txt');
    print(model);
  }

  Future<List> classifyImage(File file) async {
    isRecognizing = true;
    notifyListeners();
    List _classifiedObjects = await Tflite.detectObjectOnImage(
      path: file.path,
      model: "SSDMobileNet",
      imageMean: 127.5,
      imageStd: 127.5,
      threshold: 0.4,
      numResultsPerClass: 1,
    );
    isRecognizing = false;
    notifyListeners();
    return _classifiedObjects;
  }
}
