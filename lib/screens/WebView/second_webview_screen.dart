import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'face_scan_screen.dart';
import 'webview_screen.dart';


class SecondWebViewPage extends StatefulWidget {
  final String url;
  const SecondWebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  _SecondWebViewPageState createState() => _SecondWebViewPageState();
}

class _SecondWebViewPageState extends State<SecondWebViewPage> {
  late WebViewController _controller;
  bool _isWebViewInitialized = false;
  String? storedFaceScanKey;
  String? storedScanType;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// 📌 Initialize WebView
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..clearCache()
      ..clearLocalStorage()
      ..loadRequest(Uri.parse(widget.url)) 
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            debugPrint("🌍 Requested URL: ${request.url}");

            //final RegExp faceScanRegex = RegExp(
            //    r"https://20b9-197-211-59-55\.ngrok-free\.app/auth/students/face-scan/([\w\d]+)");

            // Regex to match both face scan and attendance scan routes
            final RegExp scanRegex = RegExp(
                  r"https://60c2-102-88-108-224\.ngrok-free\.app/(auth/students/face-scan|students/attendance-scan)/([\w\d]+)?");

 
            final match = scanRegex.firstMatch(request.url);

            if (match != null) {

              String scanType = match.group(1) ?? ""; // Extract scan type
              String scanKey = match.group(2) ?? ""; // Extract scan key

              //String faceScanKey = match.group(1) ?? "";

              debugPrint("🔑 Extracted Face Scan Key: $scanKey");
              debugPrint("🛤️ Scan Type Detected: $scanType");

              if (scanKey.isNotEmpty) {
                // Store the key for later use

                _storeScanData(scanKey, scanType);

                debugPrint("🔍 Face scan detected! Redirecting to FaceScanScreen...");
                Future.delayed(Duration(milliseconds: 100), () {
                  if (mounted) {
                    _launchScan(scanKey, scanType);
                  }else {
                    debugPrint("🔍 Face scan not mounted!");
                  }
                });
              } else {
                debugPrint("⚠️ FaceScan Key extraction failed!");
              }

              return NavigationDecision.prevent; // Stop WebView navigation
            } else {
              debugPrint("⚠️ No match found in URL! Regex failed.");
            }
        
            return NavigationDecision.navigate;
          },
        ),
      )

      // ✅ Add JavaScript Channel to receive messages from JS
      ..addJavaScriptChannel(
        "FlutterChannel",
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("📩 JS Message: ${message.message}");
        },
      );

    setState(() {
      _isWebViewInitialized = true;
    });

    // ✅ Start location updates
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ✅ Check location permission
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("⚠️ Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("⚠️ Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("❌ Location permissions are permanently denied.");
      return;
    }

    // ✅ Start periodic updates (every 10 seconds, even if stationary)
    _updateLocationPeriodically();

    // ✅ Listen for location changes
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        //timeLimit: Duration(seconds: 10),
      ),
    ).listen((Position position) {
      double lat = position.latitude;
      double lng = position.longitude;

      debugPrint("📍 New Location: Lat: $lat, Lng: $lng");

      // ✅ Send location to WebView
      _sendLocationToWebView(lat, lng);

    });
  }

  // ✅ Periodic updates (every 10 seconds)
  void _updateLocationPeriodically() async {
    while (true) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        double lat = position.latitude;
        double lng = position.longitude;

        debugPrint("⏳ Periodic Location Update: Lat: $lat, Lng: $lng");
        _sendLocationToWebView(lat, lng);
      } catch (e) {
        debugPrint("❌ Failed to get location: $e");
      }

      await Future.delayed(const Duration(seconds: 10)); // Repeat every 10 seconds
    }
  }

  // ✅ Send location to WebView
  void _sendLocationToWebView(double lat, double lng) {
    Future.delayed(const Duration(seconds: 2), () {
      _controller.runJavaScript(
        "window.updateUserLocation($lat, $lng);",
      );
    });
  }


  /// 📌 Store the extracted key
  void _storeScanData(String key, String scanType) {
    setState(() {
      storedFaceScanKey = key; // Save the key in a state variable
      storedScanType = scanType;
    });
  }

  /// 📌 Launch FaceScanScreen
  void _launchScan([String? faceScanKey, String? scanType]) {
    debugPrint("🚀 Launching FaceScanScreen with Key: $faceScanKey and Type: $scanType");

    if (faceScanKey == null || faceScanKey.isEmpty) {
      debugPrint("⚠️ No FaceScan Key available!");
      return; // Exit if no key is available
    }

    if (scanType == null || scanType.isEmpty) {
      debugPrint("⚠️ Scan Type is missing!");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceScanScreen(
          faceScanKey: faceScanKey,
          onScanComplete: (File scanResult) async {
            debugPrint("🔄 Face Scan Completed: ${scanResult.path}");
            bool success = await _sendScanResult(scanResult, faceScanKey, scanType);

            if (success) {
              debugPrint("✅ Face scan successful. Reloading WebView...");
              _controller.runJavaScript("window.onFaceScanComplete('${scanResult.path}');");
              _controller.loadRequest(Uri.parse(widget.url)); // Reload WebView
            } else {
              debugPrint("❌ Face scan failed. API request was unsuccessful.");
            }
          },
        ),
      ),
    ).then((_) {
      debugPrint("🔙 Returned from FaceScanScreen");
    });
  }

  Future<String> encodeImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  /// 📌 **Pull-to-Refresh Method**
  Future<void> _reloadWebView() async {
    if (_isWebViewInitialized) {
      debugPrint("🔄 Refreshing WebView...");
      _controller.reload();
    }
  }


  /// 📌 Send face scan result to API
  Future<bool> _sendScanResult(File imageFile, String? faceScanKey, String scanType) async {
    if (faceScanKey == null || faceScanKey.isEmpty) {
      debugPrint("⚠️ FaceScan Key is missing, aborting API request.");
      return false;
    }
    //const String apiUrl = "https://20b9-197-211-59-55.ngrok-free.app/auth/students/process-face-scan"; // Update with actual API

    
    // Determine API URL based on scan type
    String apiUrl;
    if (scanType.contains("face-scan")) {
      apiUrl = "https://60c2-102-88-108-224.ngrok-free.app/auth/students/process-face-scan";
    } else if (scanType.contains("attendance-scan")) {
      apiUrl = "https://60c2-102-88-108-224.ngrok-free.app/students/recognize-face";
    } else {
      debugPrint("⚠️ Unknown scan type: $scanType");
      return false;
    }

    try {
      // Convert the image to Base64
      String scanResult = await encodeImageToBase64(imageFile);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "scanResult": scanResult,
          "faceScanKey": faceScanKey,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint("✅ API Response: ${response.body}");
        String redirectUrl = responseData['redirect_url'];

        if (redirectUrl.isEmpty) {
          debugPrint("⚠️ No redirect URL provided!");
        }

        debugPrint("⚠️  Redirect URL: $redirectUrl");
        setState(() {
          _errorMessage = null; // Clear previous errors
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewPage(url: redirectUrl),
          ),
        );

        return true;
      } else {
        
        debugPrint("⚠️ API Error: ${response.statusCode}, ${response.body}");
        setState(() {
          _errorMessage = "Error: ${response.statusCode} - ${response.body}";
        });

        // Show retry option
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text("Verification Failed"),
    content: Text("Face verification failed. Would you like to try again?"),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.pop(context); // Close the dialog

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FaceScanScreen(
                faceScanKey: faceScanKey,
                onScanComplete: (File scanResult) async {
                  debugPrint("🔄 Face Scan Completed: ${scanResult.path}");
                  bool success = await _sendScanResult(scanResult, faceScanKey, scanType);

                  if (success) {
                    debugPrint("✅ Face scan successful. Reloading WebView...");
                    _controller.runJavaScript("window.onFaceScanComplete('${scanResult.path}');");
                    _controller.loadRequest(Uri.parse(widget.url)); // Reload WebView
                  } else {
                    debugPrint("❌ Face scan failed. API request was unsuccessful.");
                  }
                },
              ),
            ),
          ).then((_) {
            debugPrint("🔙 Returned from FaceScanScreen");
          });
        },
        child: Text("Retry"),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text("Cancel"),
      ),
    ],
  ),
);

        return false;
      }
    } catch (e) {
      debugPrint("❌ API Request Failed: $e");
      setState(() {
        _errorMessage = "Network Error: Unable to connect to the server.";
      });
      return false;
    }
  }

  /// 📌 Handle back navigation inside WebView
  Future<bool> _handleBackPress() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: _isWebViewInitialized
                  ? RefreshIndicator(
                    onRefresh: _reloadWebView,
                    child: NotificationListener<ScrollUpdateNotification>(
                      onNotification: (scrollNotification) {
                        return false; // Allow normal scrolling
                      },
                      child: WebViewWidget(controller: _controller),
                    ),
                  )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
