import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final LocalAuthentication auth = LocalAuthentication();

  List<BiometricType> availableBiometrics = [];
  String? selectedBiometric;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  // FETCH DEVICE BIOMETRICS
  Future<void> _loadBiometrics() async {
    try {
      List<BiometricType> biometrics = await auth.getAvailableBiometrics();
      setState(() => availableBiometrics = biometrics);
    } catch (e) {
      print("Error fetching biometrics: $e");
    }
  }

  // AUTHENTICATE
  Future<void> _authenticate(String type) async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Verify using $type',
        biometricOnly: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authenticated
                ? "$type Authentication Successful!"
                : "$type Authentication Failed",
          ),
        ),
      );
    } catch (e) {
      print("Auth error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Security",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Biometric Authentication",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Select Biometric Method",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Choose biometric type"),
                    value: selectedBiometric,
                    items: _buildBiometricItems(),
                    onChanged: (value) {
                      setState(() => selectedBiometric = value);
                      _authenticate(value!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BIOMETRIC LIST ITEMS
  List<DropdownMenuItem<String>> _buildBiometricItems() {
    Map<BiometricType, String> names = {
      BiometricType.fingerprint: "Fingerprint",
      BiometricType.face: "Face Recognition",
      BiometricType.iris: "Iris Scan",
    };

    Icon _icon(BiometricType type) {
      switch (type) {
        case BiometricType.fingerprint:
          return const Icon(Icons.fingerprint, color: Colors.blue);
        case BiometricType.face:
          return const Icon(Icons.face, color: Colors.deepPurple);
        case BiometricType.iris:
          return const Icon(Icons.remove_red_eye, color: Colors.teal);
        default:
          return const Icon(Icons.device_unknown);
      }
    }

    return availableBiometrics.map((b) {
      return DropdownMenuItem(
        value: names[b],
        child: Row(
          children: [
            _icon(b),
            const SizedBox(width: 10),
            Text(names[b] ?? "Unknown"),
          ],
        ),
      );
    }).toList();
  }
}
