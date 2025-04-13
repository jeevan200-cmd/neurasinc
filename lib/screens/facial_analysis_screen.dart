import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import '../services/smartwatch_service.dart';

class FacialAnalysisScreen extends StatefulWidget {
  const FacialAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<FacialAnalysisScreen> createState() => _FacialAnalysisScreenState();
}

class _FacialAnalysisScreenState extends State<FacialAnalysisScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraPermissionGranted = false;
  bool _isAnalyzing = false;
  String _analysisResult = '';
  final SmartwatchService _smartwatchService = SmartwatchService();
  final bool _isConnectingWatch = false;
  StreamSubscription? _heartRateSubscription;
  String _watchStatus = 'Not connected';
  StreamSubscription? _watchStatusSubscription;
  HeartRateData? _lastHeartRate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
    _initSmartwatch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _heartRateSubscription?.cancel();
    _watchStatusSubscription?.cancel();
    _smartwatchService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isCameraPermissionGranted = status.isGranted;
    });

    if (status.isGranted) {
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _analysisResult = 'No cameras found';
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = cameraController;

      await cameraController.initialize();

      if (!mounted) return;

      setState(() {});

      // Start periodic analysis
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted && !_isAnalyzing) {
          _analyzeCurrentFrame();
        }
      });
    } catch (e) {
      setState(() {
        _analysisResult = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isAnalyzing) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final image = await _controller!.takePicture();

      // Simulate analysis (replace with actual analysis logic)
      await Future.delayed(const Duration(milliseconds: 500));
      final result = DateTime.now().second % 2 == 0
          ? 'Stress Level: Low\nEmotion: Calm'
          : 'Stress Level: Medium\nEmotion: Focused';

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analysisResult = 'Analysis error: ${e.toString()}';
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _initSmartwatch() async {
    // Listen to status updates
    _watchStatusSubscription =
        _smartwatchService.statusController.stream.listen((status) {
      setState(() => _watchStatus = status);
    });

    // Listen to heart rate updates
    _heartRateSubscription =
        _smartwatchService.heartRateController.stream.listen((data) {
      setState(() => _lastHeartRate = data);
    });

    // Start scanning for smartwatches
    await _smartwatchService.startScan();
  }

  Widget _buildHeartRateDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.watch,
                color:
                    _smartwatchService.isConnected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _watchStatus,
                  style: TextStyle(
                    color: _smartwatchService.isConnected
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (_lastHeartRate != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '${_lastHeartRate!.heartRate} BPM',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              'Last updated: ${_formatTimestamp(_lastHeartRate!.timestamp)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (!_smartwatchService.isConnected)
            ElevatedButton.icon(
              onPressed: _smartwatchService.startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraPermissionGranted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Camera permission is required',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Facial Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeCamera,
          ),
          IconButton(
            icon: const Icon(Icons.watch),
            onPressed: _initSmartwatch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeartRateDisplay(),
          Expanded(
            child: _controller == null || !_controller!.value.isInitialized
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      if (_isAnalyzing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Analysis Results',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_analysisResult.isNotEmpty)
                                Text(
                                  _analysisResult,
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
