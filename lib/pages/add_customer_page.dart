import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AddCustomerPage extends StatefulWidget {
  final Customer? customerToEdit;
  const AddCustomerPage({super.key, this.customerToEdit});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtl;
  late final TextEditingController _phoneCtl;
  late final TextEditingController _dateCtl;
  late final TextEditingController _ghanaCardController;
  late final TextEditingController _licenseController;

  // Store image paths as Strings for better state management
  String? _ghanaCardFrontPath;
  String? _ghanaCardBackPath;
  String? _licenseFrontPath;
  String? _licenseBackPath;
  String? _profilePicturePath;

  final picker = ImagePicker();
  bool get isEditMode => widget.customerToEdit != null;
  String _countryCode = '+233';
  String _localPhoneNumber = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customerToEdit;

    _nameCtl = TextEditingController(text: customer?.name ?? '');
    _phoneCtl = TextEditingController(text: customer?.phone ?? '');
    _ghanaCardController =
        TextEditingController(text: customer?.ghanaCardNumber ?? '');
    _licenseController =
        TextEditingController(text: customer?.licenseIdNumber ?? '');
    _dateCtl = TextEditingController(
      text: customer?.dateJoined ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    // Pre-fill image paths if in edit mode
    if (isEditMode) {
      _ghanaCardFrontPath = customer?.ghanaCardFrontImage;
      _ghanaCardBackPath = customer?.ghanaCardBackImage;
      _licenseFrontPath = customer?.licenseFrontImage;
      _licenseBackPath = customer?.licenseBackImage;
      _profilePicturePath = customer?.profilePicture;
      final phoneParts = _extractPhoneParts(customer?.phone ?? '');
      _countryCode = phoneParts.$1;
      _localPhoneNumber = phoneParts.$2;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _dateCtl.dispose();
    _ghanaCardController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickIdImages({required bool isGhanaCard}) async {
    // Pick FRONT image
    final front = await picker.pickImage(source: ImageSource.camera);
    if (front == null) return;

    // Temporarily store the front image (not shown yet)
    String frontPath = front.path;

    // Delay to avoid context errors
    await Future.delayed(const Duration(milliseconds: 300));

    // Pick BACK image
    final back = await picker.pickImage(source: ImageSource.camera);
    if (back == null) return;

    // SAFELY update state AFTER both images are selected
    if (!mounted) return;

    setState(() {
      if (isGhanaCard) {
        _ghanaCardFrontPath = frontPath;
        _ghanaCardBackPath = back.path;
      } else {
        _licenseFrontPath = frontPath;
        _licenseBackPath = back.path;
      }
    });
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final state = Provider.of<AppState>(context, listen: false);
    setState(() => _isSaving = true);

    try {
      final parsedPhone = _extractPhoneParts(_phoneCtl.text.trim());
      final countryCodeToSend = _countryCode.isNotEmpty
          ? _countryCode
          : parsedPhone.$1;
      final localPhoneToSend = _localPhoneNumber.isNotEmpty
          ? _localPhoneNumber
          : parsedPhone.$2;

      if (isEditMode) {
        final existing = widget.customerToEdit!;
        await state.updateCustomerInApi(
          id: existing.id,
          fullName: _nameCtl.text.trim(),
          countryCode: countryCodeToSend,
          phoneNumber: localPhoneToSend,
          ghanaCardNumber: _ghanaCardController.text.trim(),
          licenseIdNumber: _licenseController.text.trim(),
          ghanaCardImagePath: _ghanaCardFrontPath ?? _ghanaCardBackPath,
          licenseIdImagePath: _licenseFrontPath ?? _licenseBackPath,
          profilePicturePath: _profilePicturePath,
          dailyLoans: existing.dailyLoans,
          softLoans: existing.softLoans,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated successfully.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      await state.addCustomerToApi(
        fullName: _nameCtl.text.trim(),
        countryCode: countryCodeToSend,
        phoneNumber: localPhoneToSend,
        ghanaCardNumber: _ghanaCardController.text.trim(),
        licenseIdNumber: _licenseController.text.trim(),
        ghanaCardImagePath: _ghanaCardFrontPath ?? _ghanaCardBackPath,
        licenseIdImagePath: _licenseFrontPath ?? _licenseBackPath,
        profilePicturePath: _profilePicturePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer created successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create customer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  (String, String) _extractPhoneParts(String completePhone) {
    if (completePhone.isEmpty) return ('+233', '');
    if (!completePhone.startsWith('+')) return (_countryCode, completePhone);
    final match = RegExp(r'^\+\d{1,4}').firstMatch(completePhone);
    if (match == null) return (_countryCode, completePhone);
    final code = match.group(0) ?? _countryCode;
    final number = completePhone.substring(code.length);
    return (code, number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Customer' : 'Add New Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              Center(
                child: Column(
                  children: [
                    _buildProfileAvatar(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickProfileFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Capture Profile'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickProfileFromGallery,
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload Profile'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Full Name
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),

              // Phone Number
              IntlPhoneField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'GH',
                initialValue: widget.customerToEdit?.phone,
                onChanged: (phone) {
                  _phoneCtl.text = phone.completeNumber;
                  _countryCode = phone.countryCode;
                  _localPhoneNumber = phone.number;
                },
              ),
              const SizedBox(height: 16),

              // Ghana Card Number
              TextFormField(
                controller: _ghanaCardController,
                decoration: const InputDecoration(
                  labelText: 'Ghana Card Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // License ID Number
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'License ID Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              // --- NEW GHANA CARD UI ---
              _buildIdCaptureSection(
                title: 'Ghana Card Images',
                onCameraTap: () => _pickIdImages(isGhanaCard: true),
                onGalleryTap: () => _pickFromGallery(isGhanaCard: true),
                frontImagePath: _ghanaCardFrontPath,
                backImagePath: _ghanaCardBackPath,

              ),
              const SizedBox(height: 25),

              // --- NEW LICENSE CARD UI ---
              _buildIdCaptureSection(
                title: 'License Images',
                onCameraTap: () => _pickIdImages(isGhanaCard: false),
                onGalleryTap: () => _pickFromGallery(isGhanaCard: false),
                frontImagePath: _licenseFrontPath,
                backImagePath: _licenseBackPath,
              ),
              const SizedBox(height: 40),

              // Save Button
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(isEditMode ? 'Update Customer' : 'Save Customer'),
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdCaptureSection({
    required String title,
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
    String? frontImagePath,
    String? backImagePath,
  }) {
    final showPreview =
        frontImagePath != null &&
            frontImagePath.isNotEmpty &&
            backImagePath != null &&
            backImagePath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCameraTap,
                icon: const Icon(Icons.camera_alt),
                label: Text("Capture $title"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onGalleryTap,
                icon: const Icon(Icons.upload),
                label: Text("Upload $title"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (showPreview)
          Row(
            children: [
              Expanded(
                child: _buildImagePreview(
                  imagePath: frontImagePath,
                  label: "Front",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImagePreview(
                  imagePath: backImagePath,
                  label: "Back",
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _pickFromGallery({required bool isGhanaCard}) async {
    final front = await picker.pickImage(source: ImageSource.gallery);
    if (front == null) return;

    final back = await picker.pickImage(source: ImageSource.gallery);
    if (back == null) return;

    if (!mounted) return;
    setState(() {
      if (isGhanaCard) {
        _ghanaCardFrontPath = front.path;
        _ghanaCardBackPath = back.path;
      } else {
        _licenseFrontPath = front.path;
        _licenseBackPath = back.path;
      }
    });
  }

  Future<void> _pickProfileFromCamera() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null || !mounted) return;
    setState(() => _profilePicturePath = image.path);
  }

  Future<void> _pickProfileFromGallery() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    setState(() => _profilePicturePath = image.path);
  }

  Widget _buildProfileAvatar() {
    final file = _profileFileOrNull();
    if (file != null) {
      return ClipOval(
        child: SizedBox(
          width: 80,
          height: 80,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildProfileInitialAvatar(),
          ),
        ),
      );
    }

    final bytes = _profileBytesOrNull();
    if (bytes != null) {
      return ClipOval(
        child: SizedBox(
          width: 80,
          height: 80,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildProfileInitialAvatar(),
          ),
        ),
      );
    }

    return _buildProfileInitialAvatar();
  }

  Widget _buildProfileInitialAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey.shade400,
      child: Text(
        _initialFromName(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
      ),
    );
  }

  File? _profileFileOrNull() {
    final value = _profilePicturePath;
    if (value == null || value.isEmpty) return null;
    final file = File(value);
    if (file.existsSync()) {
      return file;
    }
    return null;
  }

  Uint8List? _profileBytesOrNull() {
    final value = _profilePicturePath;
    if (value == null || value.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(value));
    } catch (_) {
      return null;
    }
  }

  String _initialFromName() {
    final trimmed = _nameCtl.text.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }



  // Widget _buildIdCaptureSection({
  //   required String title,
  //   required VoidCallback onTap,
  //   String? frontImagePath,
  //   String? backImagePath,
  // })
  // {
  //   final showPreview =
  //       frontImagePath != null &&
  //           frontImagePath.isNotEmpty &&
  //           backImagePath != null &&
  //           backImagePath.isNotEmpty;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       ElevatedButton.icon(
  //         onPressed: onTap,
  //         icon: const Icon(Icons.camera_alt),
  //         label: Text("Capture $title"),
  //       ),
  //       const SizedBox(height: 12),
  //
  //       if (showPreview)  // 🔥 ONLY SHOW WHEN BOTH ARE READY
  //         Row(
  //           children: [
  //             Expanded(child: _buildImagePreview(imagePath: frontImagePath, label: "Front")),
  //             const SizedBox(width: 16),
  //             Expanded(child: _buildImagePreview(imagePath: backImagePath, label: "Back")),
  //           ],
  //         ),
  //     ],
  //   );
  // }

  Widget _buildImagePreview({String? imagePath, required String label}) {
    final valid = imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1.586,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            clipBehavior: Clip.antiAlias,
            child: valid
                ? Image.file(File(imagePath), fit: BoxFit.cover)
                : const Center(
              child: Icon(Icons.image_not_supported_outlined,
                  color: Colors.grey, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}
