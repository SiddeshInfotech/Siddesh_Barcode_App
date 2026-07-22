import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraView extends StatefulWidget {
  final MobileScannerController controller;
  final Function(BarcodeCapture) onDetect;

  const CameraView({
    Key? key,
    required this.controller,
    required this.onDetect,
  }) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Camera Permission Denied', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        content: const Text('Please enable camera access in your settings to scan barcodes.', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3BA8FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3BA8FF)));
    }

    if (!_hasPermission) {
      return const Center(
        child: Text(
          'Camera access is required',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
        ),
      );
    }

    return MobileScanner(
      controller: widget.controller,
      onDetect: widget.onDetect,
      errorBuilder: (context, error) {
        return Center(
          child: Text(
            'Error starting camera: ${error.errorCode}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }
}
