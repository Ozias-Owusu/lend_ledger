import 'dart:io';
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

  final picker = ImagePicker();
  bool get isEditMode => widget.customerToEdit != null;

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

    final state = Provider.of<AppState>(context, listen: false);

    if (isEditMode) {
      await state.updateCustomer(
        id: widget.customerToEdit!.id,
        name: _nameCtl.text,
        phone: _phoneCtl.text,
        ghanaCardNumber: _ghanaCardController.text,
        licenseIdNumber: _licenseController.text,
        dateJoined: _dateCtl.text,
        loanType: widget.customerToEdit!.loanType,
        ghanaCardFrontImage: _ghanaCardFrontPath,
        ghanaCardBackImage: _ghanaCardBackPath,
        licenseFrontImage: _licenseFrontPath,
        licenseBackImage: _licenseBackPath,
        vehicle: '', // vehicle is deprecated but required by the function
      );
    } else {
      await state.addCustomer(
        name: _nameCtl.text,
        phone: _phoneCtl.text,
        dateJoined: _dateCtl.text,
        ghanaCardNumber: _ghanaCardController.text,
        licenseIdNumber: _licenseController.text,
        loanType: 'daily', // Default value
        ghanaCardFrontImage: _ghanaCardFrontPath,
        ghanaCardBackImage: _ghanaCardBackPath,
        licenseFrontImage: _licenseFrontPath,
        licenseBackImage: _licenseBackPath,
        vehicle: '', // vehicle is deprecated
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
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
                  onPressed: _saveCustomer,
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
            // Expanded(
            //   child: ElevatedButton.icon(
            //     onPressed: onCameraTap,
            //     icon: const Icon(Icons.camera_alt),
            //     label: Text("Capture $title"),
            //   ),
            // ),
            // const SizedBox(width: 12),
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
                ? Image.file(File(imagePath!), fit: BoxFit.cover)
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
