import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lend_ledger/models/customer.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../utils/image_data_utils.dart';

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
    _ghanaCardController = TextEditingController(
      text: customer?.ghanaCardNumber ?? '',
    );
    _licenseController = TextEditingController(
      text: customer?.licenseIdNumber ?? '',
    );
    _dateCtl = TextEditingController(
      text:
          customer?.dateJoined ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
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
        title: Text(
          isEditMode ? 'Edit Customer' : 'Add New Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Enter customer details and documents',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildProfileAvatar(),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: InkWell(
                            onTap: _pickProfileFromCamera,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9A1A0),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _topActionButton(
                            onPressed: _pickProfileFromCamera,
                            icon: Icons.camera_alt_outlined,
                            title: 'Capture Photo',
                            subtitle: 'Use camera',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _topActionButton(
                            onPressed: _pickProfileFromGallery,
                            icon: Icons.upload_outlined,
                            title: 'Upload Photo',
                            subtitle: 'From gallery',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),

              _sectionHeader('Personal Information'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameCtl,
                onChanged: (_) => setState(() {}),
                decoration: _softInputDecoration(
                  label: 'Full Name',
                  hint: 'Enter full name',
                  prefixIcon: Icons.person_outline,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEDEDED)),
                ),
                child: IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  initialCountryCode: 'GH',
                  initialValue: widget.customerToEdit?.phone,
                  disableLengthCheck: true,
                  onChanged: (phone) {
                    _phoneCtl.text = phone.completeNumber;
                    _countryCode = phone.countryCode;
                    _localPhoneNumber = phone.number;
                  },
                ),
              ),
              const SizedBox(height: 22),

              _sectionHeader('Identification Details'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ghanaCardController,
                decoration: _softInputDecoration(
                  label: 'Ghana Card Number',
                  hint: 'Enter Ghana Card number',
                  prefixIcon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _licenseController,
                decoration: _softInputDecoration(
                  label: 'License ID Number',
                  hint: 'Enter License ID number',
                  prefixIcon: Icons.verified_user_outlined,
                ),
              ),
              const SizedBox(height: 24),

              _sectionHeader('Document Images'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _documentActionTile(
                      title: 'Ghana Card Images',
                      subtitle: 'Capture or upload',
                      icon: Icons.credit_card_outlined,
                      onTap: () => _pickIdImages(isGhanaCard: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _documentActionTile(
                      title: 'Upload Ghana Card',
                      subtitle: 'From gallery',
                      icon: Icons.upload_file_outlined,
                      onTap: () => _pickFromGallery(isGhanaCard: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _documentActionTile(
                      title: 'License Images',
                      subtitle: 'Capture or upload',
                      icon: Icons.badge_outlined,
                      onTap: () => _pickIdImages(isGhanaCard: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _documentActionTile(
                      title: 'Upload License',
                      subtitle: 'From gallery',
                      icon: Icons.upload_file_outlined,
                      onTap: () => _pickFromGallery(isGhanaCard: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_ghanaCardFrontPath != null &&
                  _ghanaCardBackPath != null) ...[
                const Text(
                  'Ghana Card preview',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildImagePreview(
                        imagePath: _ghanaCardFrontPath,
                        label: "Front",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildImagePreview(
                        imagePath: _ghanaCardBackPath,
                        label: "Back",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_licenseFrontPath != null && _licenseBackPath != null) ...[
                const Text(
                  'License preview',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildImagePreview(
                        imagePath: _licenseFrontPath,
                        label: "Front",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildImagePreview(
                        imagePath: _licenseBackPath,
                        label: "Back",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : isEditMode
                        ? 'Update Customer'
                        : 'Save Customer',
                  ),
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD79A9A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
    );
  }

  InputDecoration _softInputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFFD39A9A)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEDEDED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEDEDED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD39A9A), width: 1.4),
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }

  Widget _topActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFF7ECEC),
              child: Icon(icon, size: 17, color: const Color(0xFFD39A9A)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFF7ECEC),
              child: Icon(icon, size: 15, color: const Color(0xFFD39A9A)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD39A9A)),
          ],
        ),
      ),
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
      radius: 54,
      backgroundColor: const Color(0xFFF3EFEF),
      child: Text(
        _initialFromName(),
        style: const TextStyle(
          color: Color(0xFFCC9A9A),
          fontWeight: FontWeight.bold,
          fontSize: 34,
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
    return ImageDataUtils.decodeToBytes(_profilePicturePath);
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
    final hasPath = imagePath != null && imagePath.isNotEmpty;
    final safePath = imagePath ?? '';
    final file = hasPath ? File(safePath) : null;
    final fileExists = file != null && file.existsSync();
    final memoryBytes = hasPath ? ImageDataUtils.decodeToBytes(imagePath) : null;

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
            child: fileExists
                ? Image.file(file, fit: BoxFit.cover)
                : (memoryBytes != null
                    ? Image.memory(memoryBytes, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      )),
          ),
        ),
      ],
    );
  }
}
