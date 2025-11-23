import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/children_provider.dart';
import '../models/child_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR Code'),
        actions: [
          IconButton(
            onPressed: () => cameraController.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) async {
                final String? barcode = capture.barcodes.first.rawValue;
                
                if (barcode != null) {
                  // Process the scanned QR code
                  await _processScannedCode(
                    context, 
                    barcode, 
                    authProvider, 
                    childrenProvider
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Scannez le QR code du profil de l\'enfant pour établir un lien',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processScannedCode(
    BuildContext context,
    String scannedCode,
    AuthProvider authProvider,
    ChildrenProvider childrenProvider,
  ) async {
    // Verify that this is a MindGuard QR code
    if (!scannedCode.startsWith('mindguard://link_child/')) {
      _showError(context, 'Code QR invalide. Veuillez scanner un code MindGuard.');
      return;
    }

    try {
      // Extract child ID from the QR code
      List<String> parts = scannedCode.split('/');
      if (parts.length < 4) {
        _showError(context, 'Code QR format invalide.');
        return;
      }

      String childId = parts[3];

      // Verify that this user is a parent
      if (authProvider.userModel?.role != 'parent') {
        _showError(context, 'Seuls les parents peuvent lier des enfants.');
        return;
      }

      // Create a connection request in Firestore that the child can approve
      await _createConnectionRequest(
        authProvider.userModel!.uid,
        childId,
        authProvider.userModel!.name ?? 'Unknown Parent',
      );

      // Show success message
      if (mounted) {
        _showSuccess(context, 'Demande de connexion envoyée! L\'enfant doit approuver la demande.');
        // Navigate back to children management screen after a delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      _showError(context, 'Erreur lors du traitement du QR code: $e');
    }
  }

  Future<void> _createConnectionRequest(
    String parentId,
    String childId,
    String parentName,
  ) async {
    // Create a connection request in a separate collection
    await FirebaseFirestore.instance.collection('connection_requests').add({
      'parentId': parentId,
      'childId': childId,
      'parentName': parentName,
      'status': 'pending', // pending, approved, rejected
      'requestedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)), // Request expires in 7 days
      ),
    });
  }

  void _showError(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccess(BuildContext context, String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}