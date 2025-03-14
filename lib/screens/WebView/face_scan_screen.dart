import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class FaceScanScreen extends StatefulWidget {
  final String? faceScanKey;
  final Function(File) onScanComplete;

  FaceScanScreen({Key? key, this.faceScanKey, required this.onScanComplete});

  @override
  _FaceScanScreenState createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        debugPrint("❌ No cameras available");
        return;
      }

      _cameraController = CameraController(
        //cameras![1], // Use front camera
        cameras!.length > 1 ? cameras![1] : cameras![0],
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("❌ Camera error: $e");
    }
  }

  Future<void> _captureFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      debugPrint("❌ Camera not initialized or already capturing!");
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile xFile = await _cameraController!.takePicture();
      //Uint8List imageBytes = await File(imageFile.path).readAsBytes();
      //String base64Image = base64Encode(imageBytes);
      final File imageFile = File(xFile.path); // Convert XFile to File
      
      debugPrint("✅ Face scan captured successfully!");
      widget.onScanComplete(imageFile);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("❌ Capture error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    //_cameraController?.dispose();
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Face Scan")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Set Up Face Scan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Use your face to securely access your account. Just look at the camera and capture your image!",
              textAlign: TextAlign.center,
            ),
          ),
          _cameraController == null || !_cameraController!.value.isInitialized
              ? CircularProgressIndicator()
              : Container(
                  height: 300,
                  width: 250,
                  child: CameraPreview(_cameraController!),
                ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isCapturing ? null : _captureFace,
            child: Text("Capture Face"),
          ),
        ],
      ),
    );
  }
}
