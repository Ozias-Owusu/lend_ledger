import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lend_ledger/models/auth/user_profile.dart';
import 'package:lend_ledger/pages/change_password_sheet.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:lend_ledger/utils/snackbar_utils.dart';
import 'package:lend_ledger/widgets/user_profile_avatar.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _picker = ImagePicker();
  static const _maskedPassword = '••••••••••••';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordDisplayController =
      TextEditingController(text: _maskedPassword);

  String? _localProfileImagePath;
  bool _showPasswordPreview = false;

  bool _loadingProfile = true;
  String? _loadError;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    final cached = context.read<AppState>().currentUserProfile;
    if (cached != null) {
      _applyProfile(cached);
      _loadingProfile = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (_profile == null) {
      setState(() {
        _loadingProfile = true;
        _loadError = null;
      });
    }

    final appState = context.read<AppState>();
    final profile = await appState.loadCurrentUserProfile(
      force: true,
      notify: false,
    );

    if (!mounted) return;

    if (profile == null) {
      setState(() {
        _loadingProfile = false;
        _loadError = appState.userProfileError ?? 'Could not load profile.';
      });
      return;
    }

    _applyProfile(profile);
    setState(() => _loadingProfile = false);
  }

  void _applyProfile(UserProfile profile) {
    _profile = profile;
    _nameController.text = profile.fullName;
    _emailController.text = profile.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordDisplayController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img != null && mounted) {
      setState(() => _localProfileImagePath = img.path);
    }
  }

  Future<void> _onPasswordFieldTap() async {
    final change = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password?'),
        content: const Text(
          'You will need your current password to set a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (change != true || !mounted) return;

    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ChangePasswordSheet(),
    );

    if (success == true && mounted) {
      SnackbarUtils.showSuccess(context, 'Password updated successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildErrorState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        UserProfileAvatar(
                          profile: _profile,
                          radius: 60,
                          localImagePath: _localProfileImagePath,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              onTap: _pickProfileImage,
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.camera_alt, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _readOnlyField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _readOnlyField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  _passwordField(),
                ],
              ),
            ),
    );
  }

  Widget _readOnlyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordDisplayController,
      readOnly: true,
      obscureText: !_showPasswordPreview,
      onTap: _onPasswordFieldTap,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _showPasswordPreview
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _showPasswordPreview = !_showPasswordPreview);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _onPasswordFieldTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
