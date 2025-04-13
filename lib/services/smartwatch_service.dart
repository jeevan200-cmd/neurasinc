import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartwatchService {
  static final SmartwatchService _instance = SmartwatchService._internal();
  factory SmartwatchService() => _instance;
  SmartwatchService._internal();

  BluetoothDevice? _connectedDevice;
  final StreamController<HeartRateData> heartRateController =
      StreamController<HeartRateData>.broadcast();
  final StreamController<String> statusController =
      StreamController<String>.broadcast();
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 3;

  // Common service UUIDs for different watch brands
  static const Map<String, List<String>> WATCH_SERVICES = {
    'HEART_RATE': [
      "0000180d-0000-1000-8000-00805f9b34fb", // Standard HR service
      "180d", // Short version
      "0x180D",
    ],
    'MI_BAND': [
      "0000fee0-0000-1000-8000-00805f9b34fb",
      "fee0",
    ],
    'FITBIT': [
      "558dfa00-4fa8-4105-9f02-4eaa93e62980",
    ],
    'GALAXY_WATCH': [
      "00001800-0000-1000-8000-00805f9b34fb",
    ],
  };

  // Common characteristic UUIDs
  static const Map<String, List<String>> WATCH_CHARACTERISTICS = {
    'HEART_RATE': [
      "00002a37-0000-1000-8000-00805f9b34fb", // Standard HR measurement
      "2a37", // Short version
    ],
    'MI_BAND_HR': [
      "00000002-0000-3512-2118-0009af100700",
    ],
    'FITBIT_HR': [
      "558dfa01-4fa8-4105-9f02-4eaa93e62980",
    ],
  };

  Future<bool> requestPermissions() async {
    try {
      developer.log('Requesting Bluetooth permissions...');
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;
      final location = await Permission.location.status;

      developer.log(
          'Current permission status - Scan: $bluetoothScan, Connect: $bluetoothConnect, Location: $location');

      if (!bluetoothScan.isGranted ||
          !bluetoothConnect.isGranted ||
          !location.isGranted) {
        final results = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();

        developer.log('Permission request results: $results');

        bool allGranted = results.values.every((status) => status.isGranted);
        statusController.add(allGranted
            ? 'All permissions granted'
            : 'Some permissions were denied: ${results.toString()}');
        return allGranted;
      }
      return true;
    } catch (e) {
      developer.log('Error requesting permissions: $e', error: e);
      statusController.add('Permission error: $e');
      return false;
    }
  }

  Future<void> startScan() async {
    if (_isScanning) {
      developer.log('Already scanning for devices');
      statusController.add('Already scanning...');
      return;
    }

    try {
      // Check Bluetooth state
      final adapterState = await FlutterBluePlus.adapterState.first;
      developer.log('Bluetooth adapter state: $adapterState');

      if (adapterState != BluetoothAdapterState.on) {
        statusController.add('Please enable Bluetooth');
        developer.log('Bluetooth is not enabled');
        return;
      }

      if (!await requestPermissions()) {
        developer.log('Required permissions not granted');
        return;
      }

      _isScanning = true;
      statusController.add('Starting scan...');

      // Monitor Bluetooth state changes
      _stateSubscription?.cancel();
      _stateSubscription = FlutterBluePlus.adapterState.listen(
        (state) {
          developer.log('Bluetooth state changed: $state');
          if (state != BluetoothAdapterState.on) {
            statusController.add('Bluetooth turned off');
            stopScan();
          }
        },
        onError: (error) {
          developer.log('Bluetooth state monitoring error: $error',
              error: error);
        },
      );

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          for (ScanResult result in results) {
            if (result.device.name.isNotEmpty) {
              developer.log(
                  'Found device: ${result.device.name} (${result.device.id})');
              if (_isLikelySmartwatch(result.device.name)) {
                statusController.add('Found smartwatch: ${result.device.name}');
                await connectToDevice(result.device);
                await stopScan();
                return;
              }
            }
          }
        },
        onError: (error) {
          developer.log('Scan error: $error', error: error);
          statusController.add('Scan error: $error');
          _isScanning = false;
        },
      );
    } catch (e) {
      developer.log('Error during scan: $e', error: e);
      _isScanning = false;
      statusController.add('Error during scan: $e');
    }
  }

  bool _isLikelySmartwatch(String name) {
    final watchKeywords = [
      'watch',
      'band',
      'mi',
      'amazfit',
      'fitbit',
      'galaxy',
      'gear',
      'honor',
      'huawei',
      'wear',
      'smart',
      'fitness',
    ];

    name = name.toLowerCase();
    return watchKeywords.any((keyword) => name.contains(keyword));
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      statusController.add('Connecting to ${device.name}...');
      developer.log(
          'Attempting to connect to device: ${device.name} (${device.id})');

      // Disconnect from any existing device
      await disconnect();

      // Connect to new device
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: true,
      );

      _connectedDevice = device;
      statusController.add('Connected to ${device.name}');
      developer.log('Successfully connected to ${device.name}');

      // Monitor connection status
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen(
        (BluetoothConnectionState state) {
          developer.log('Connection state changed: $state');
          if (state == BluetoothConnectionState.disconnected) {
            _handleDisconnection();
          }
        },
        onError: (error) {
          developer.log('Connection state monitoring error: $error',
              error: error);
        },
      );

      // Discover services
      statusController.add('Discovering services...');
      List<BluetoothService> services = await device.discoverServices();
      developer.log('Discovered ${services.length} services');

      bool foundHeartRateService = false;
      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toLowerCase();
        developer.log('Examining service: $serviceUuid');

        for (var serviceType in WATCH_SERVICES.entries) {
          if (serviceType.value
              .any((uuid) => serviceUuid.contains(uuid.toLowerCase()))) {
            foundHeartRateService = true;
            developer.log('Found ${serviceType.key} service');
            statusController.add('Found ${serviceType.key} service');

            await _handleHeartRateService(service, serviceType.key);
          }
        }
      }

      if (!foundHeartRateService) {
        developer
            .log('No heart rate service found, trying alternative approach');
        statusController
            .add('No heart rate service found. Trying alternative approach...');
        for (BluetoothService service in services) {
          await _tryGenericCharacteristics(service);
        }
      }
    } catch (e) {
      developer.log('Connection error: $e', error: e);
      statusController.add('Connection error: $e');
      await _handleDisconnection();
    }
  }

  Future<void> _handleHeartRateService(
      BluetoothService service, String serviceType) async {
    try {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        String charUuid = characteristic.uuid.toString().toLowerCase();
        developer.log('Examining characteristic: $charUuid');

        for (var charType in WATCH_CHARACTERISTICS.entries) {
          if (charType.value
              .any((uuid) => charUuid.contains(uuid.toLowerCase()))) {
            developer.log('Found ${charType.key} characteristic');
            statusController.add('Found ${charType.key} characteristic');

            if (!characteristic.properties.notify &&
                !characteristic.properties.indicate) {
              developer.log(
                  'Characteristic does not support notifications or indications');
              continue;
            }

            await characteristic.setNotifyValue(true);
            characteristic.value.listen(
              (value) {
                developer.log('Received heart rate data: $value');
                _parseHeartRateData(value, serviceType);
              },
              onError: (error) {
                developer.log('Heart rate notification error: $error',
                    error: error);
                statusController.add('Heart rate notification error: $error');
              },
            );
          }
        }
      }
    } catch (e) {
      developer.log('Error setting up heart rate notifications: $e', error: e);
      statusController.add('Error setting up heart rate notifications: $e');
    }
  }

  Future<void> _tryGenericCharacteristics(BluetoothService service) async {
    for (BluetoothCharacteristic characteristic in service.characteristics) {
      if (characteristic.properties.notify ||
          characteristic.properties.indicate) {
        try {
          await characteristic.setNotifyValue(true);
          characteristic.value.listen(
            (value) => _parseHeartRateData(value, 'GENERIC'),
            onError: (error) {
              statusController.add('Notification error: $error');
            },
          );
        } catch (e) {
          // Continue trying other characteristics
        }
      }
    }
  }

  void _parseHeartRateData(List<int> value, String sourceType) {
    if (value.isEmpty) {
      developer.log('Received empty heart rate data');
      return;
    }

    try {
      int heartRate;
      double? confidence;

      developer.log('Parsing heart rate data: $value from source: $sourceType');

      switch (sourceType) {
        case 'HEART_RATE':
          final flags = value[0];
          final isFormat16Bit = flags & 0x1 != 0;
          heartRate = isFormat16Bit ? (value[1] + (value[2] << 8)) : value[1];
          developer.log(
              'Standard HR format - Flags: $flags, Is16Bit: $isFormat16Bit, Value: $heartRate');
          break;

        case 'MI_BAND':
          heartRate = value[1];
          developer.log('Mi Band format - Value: $heartRate');
          break;

        case 'FITBIT':
          heartRate = value[1];
          developer.log('Fitbit format - Value: $heartRate');
          break;

        default:
          if (value.length > 1) {
            heartRate = value[1];
          } else {
            heartRate = value[0];
          }
          developer.log('Generic format - Value: $heartRate');
      }

      if (heartRate > 0 && heartRate < 255) {
        final data = HeartRateData(
          heartRate: heartRate,
          confidence: confidence,
          timestamp: DateTime.now(),
        );
        heartRateController.add(data);
        statusController.add('Heart rate: $heartRate BPM');
        developer.log('Valid heart rate data processed: $heartRate BPM');
      } else {
        developer.log('Invalid heart rate value: $heartRate');
      }
    } catch (e) {
      developer.log('Error parsing heart rate data: $e', error: e);
      statusController.add('Error parsing heart rate data: $e');
    }
  }

  Future<void> _handleDisconnection() async {
    developer.log('Handling disconnection, attempt: $_reconnectAttempts');
    if (_reconnectAttempts < MAX_RECONNECT_ATTEMPTS &&
        _connectedDevice != null) {
      _reconnectAttempts++;
      statusController.add(
          'Connection lost. Attempting to reconnect ($_reconnectAttempts/$MAX_RECONNECT_ATTEMPTS)...');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), () async {
        try {
          await connectToDevice(_connectedDevice!);
        } catch (e) {
          developer.log('Reconnection attempt failed: $e', error: e);
        }
      });
    } else {
      developer.log(
          'Max reconnection attempts reached or no device to reconnect to');
      statusController.add(
          'Max reconnection attempts reached. Please try manually reconnecting.');
      await disconnect();
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
      developer.log('Scan stopped');
      statusController.add('Scan stopped');
    } catch (e) {
      developer.log('Error stopping scan: $e', error: e);
      statusController.add('Error stopping scan: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      _reconnectTimer?.cancel();
      _connectionSubscription?.cancel();

      if (_connectedDevice != null) {
        developer.log('Disconnecting from ${_connectedDevice!.name}');
        statusController.add('Disconnecting from ${_connectedDevice!.name}...');
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        statusController.add('Disconnected');
      }
    } catch (e) {
      developer.log('Error disconnecting: $e', error: e);
      statusController.add('Error disconnecting: $e');
      _connectedDevice = null;
    }
  }

  void dispose() {
    developer.log('Disposing SmartwatchService');
    _reconnectTimer?.cancel();
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    _connectionSubscription?.cancel();
    heartRateController.close();
    statusController.close();
    disconnect();
  }

  bool get isConnected => _connectedDevice != null;
  String get connectedDeviceName =>
      _connectedDevice?.name ?? 'No device connected';
}

class HeartRateData {
  final int heartRate;
  final double? confidence;
  final DateTime timestamp;

  HeartRateData({
    required this.heartRate,
    this.confidence,
    required this.timestamp,
  });
}
