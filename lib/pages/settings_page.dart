import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lend_ledger/pages/EditProfilePage.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- Logic moved from SecurityPage ---
  final LocalAuthentication auth = LocalAuthentication();
  List<BiometricType> _availableBiometrics = [];
  bool _isSecurityExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  // Fetch available biometrics from the device
  Future<void> _loadBiometrics() async {
    try {
      final biometrics = await auth.getAvailableBiometrics();
      if (mounted) {
        setState(() => _availableBiometrics = biometrics);
      }
    } catch (e) {
      print("Error fetching biometrics: $e");
    }
  }

  // In C:/Users/ooantwi/StudioProjects/Lend_Ledger/lib/pages/settings_page.dart

  // Authenticate using the selected method
  Future<void> _authenticate(BiometricType type) async {
    try {
      // *** FIX IS HERE: Rename AuthenticationOptions to AuthOptions ***
      final authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to verify your identity',
        biometricOnly: false,
      );

      if (authenticated) {
        final sp = await SharedPreferences.getInstance();
        await sp.setBool('biometricsEnabled', true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authenticated
                  ? "Biometric Authentication Successful!"
                  : "Authentication Failed or Canceled",
            ),
            backgroundColor: authenticated ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Auth error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // ================= ACCOUNT SECTION ==================
          _sectionTitle("Account"),

          _settingsGroup(
            children: [
              _settingsItem(
                icon: Icons.person_outline,
                title: "Edit Profile",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),

              // --- NEW EXPANDABLE SECURITY SECTION ---
              _buildSecuritySection(),

              _settingsItem(
                icon: Icons.notifications_outlined,
                title: "Notifications",
                onTap: () {},
              ),
              _settingsItem(
                icon: Icons.privacy_tip_outlined,
                title: "Privacy",
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ... (The rest of your settings sections remain the same)
          // ================= SUPPORT SECTION ==================
          _sectionTitle("Support & About"),
          _settingsGroup(
            children: [
              _settingsItem(
                icon: Icons.credit_card_outlined,
                title: "My Subscription",
                onTap: () {},
              ),
              _settingsItem(
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () {},
              ),
              _settingsItem(
                icon: Icons.article_outlined,
                title: "Terms and Policies",
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================= ACTIONS ==================
          _sectionTitle("Actions"),
          _settingsGroup(
            children: [
              _settingsItem(
                icon: Icons.flag_outlined,
                title: "Report a problem",
                onTap: () {},
              ),
              _settingsItem(
                icon: Icons.person_add_outlined,
                title: "Add Account",
                onTap: () {},
              ),
              _settingsItem(icon: Icons.logout,
                  title: "Log out",
                  onTap: () {}
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- NEW SECURITY WIDGET ---
  Widget _buildSecuritySection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline, color: Colors.black87),
          title: const Text(
            "Security",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          trailing: Icon(
            _isSecurityExpanded
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
            color: Colors.grey,
          ),
          onTap: () {
            setState(() => _isSecurityExpanded = !_isSecurityExpanded);
          },
        ),
        // This is the expandable dropdown content
        AnimatedCrossFade(
          firstChild: Container(), // Empty container when collapsed
          secondChild: _buildBiometricList(), // The list of biometrics
          crossFadeState: _isSecurityExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const Divider(height: 0, indent: 55, thickness: 0.4),
      ],
    );
  }

  // Helper to build the list of biometric options
  Widget _buildBiometricList() {
    if (_availableBiometrics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text("No biometrics available on this device."),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: _availableBiometrics.map((biometric) {
          return ListTile(
            leading: _getBiometricIcon(biometric),
            title: Text(_getBiometricName(biometric)),
            onTap: () => _authenticate(biometric),
          );
        }).toList(),
      ),
    );
  }

  // Helper methods to get names and icons for biometrics
  String _getBiometricName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return "Fingerprint";
      case BiometricType.face:
        return "Face Recognition";
      case BiometricType.iris:
        return "Iris Scan";
      case BiometricType.strong:
        return "Biometrics";
      case BiometricType.weak:
        return "Password or Pin";
      default:
        return "Unknown Biometric";
    }
  }

  Icon _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return const Icon(Icons.fingerprint, color: Colors.blue);
      case BiometricType.face:
        return const Icon(Icons.face, color: Colors.deepPurple);
      case BiometricType.iris:
        return const Icon(Icons.remove_red_eye, color: Colors.teal);
      // *** ADD THESE TWO CASES ***
      case BiometricType.strong:
        return const Icon(Icons.shield_rounded, color: Colors.green);
      case BiometricType.weak:
        return const Icon(
          Icons.security_update_good_outlined,
          color: Colors.orange,
        );
      default:
        return const Icon(Icons.device_unknown);
    }
  }

  // ============ WIDGET HELPERS (from your original code) ===================
  Widget _sectionTitle(String title) {
    // ... (This code is unchanged)
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsGroup({required List<Widget> children}) {
    // ... (This code is unchanged)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    // ... (This code is unchanged)
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 0, indent: 55, thickness: 0.4),
      ],
    );
  }
}
