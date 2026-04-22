// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class EditProfilePage extends StatefulWidget {
//   const EditProfilePage({super.key});
//
//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }
//
// class _EditProfilePageState extends State<EditProfilePage> {
//   final picker = ImagePicker();
//
//   String? _profileImage;
//
//   final TextEditingController _nameController =
//   TextEditingController(text: "Melissa Peters");
//   final TextEditingController _emailController =
//   TextEditingController(text: "melpeters@gmail.com");
//   final TextEditingController _passwordController =
//   TextEditingController(text: "********");
//   final TextEditingController _dobController =
//   TextEditingController(text: "23/05/1995");
//
//   String _selectedCountry = "Nigeria";
//   final List<String> _countries = ["Ghana", "Nigeria", "Kenya", "South Africa"];
//
//   Future<void> _pickProfileImage() async {
//     final img = await picker.pickImage(source: ImageSource.gallery);
//     if (img != null) {
//       setState(() {
//         _profileImage = img.path;
//       });
//     }
//   }
//
//   Future<void> _selectDOB() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime(1995, 5, 23),
//       firstDate: DateTime(1950),
//       lastDate: DateTime(2030),
//     );
//
//     if (picked != null) {
//       setState(() {
//         _dobController.text =
//         "${picked.day}/${picked.month}/${picked.year}";
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: const BackButton(),
//         title: const Text(
//           "Edit Profile",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             // ---------------- PROFILE IMAGE ----------------
//             Center(
//               child: Stack(
//                 children: [
//                   CircleAvatar(
//                     radius: 120,
//                     backgroundImage: _profileImage != null
//                         ? FileImage(
//                       File(_profileImage!),
//                     )
//                         : const AssetImage("assets/images/profile_1.jpg")
//                     as ImageProvider,
//                   ),
//
//                   Positioned(
//                     bottom: 0,
//                     right: 4,
//                     child: InkWell(
//                       onTap: _pickProfileImage,
//                       child: Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: const BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white,
//                         ),
//                         child: const Icon(Icons.camera_alt, size: 22),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             // ---------------- TEXT FIELDS ----------------
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(
//                 labelText: "Name",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 15),
//
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(
//                 labelText: "Email",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 15),
//
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(
//                 labelText: "Password",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 15),
//
//             // ---------------- DOB PICKER ----------------
//             TextField(
//               controller: _dobController,
//               readOnly: true,
//               decoration: InputDecoration(
//                 labelText: "Date of Birth",
//                 border: const OutlineInputBorder(),
//                 suffixIcon: const Icon(Icons.calendar_month),
//               ),
//               onTap: _selectDOB,
//             ),
//             const SizedBox(height: 15),
//
//             // ---------------- COUNTRY DROPDOWN ----------------
//             DropdownButtonFormField(
//               value: _selectedCountry,
//               items: _countries
//                   .map((c) =>
//                   DropdownMenuItem(value: c, child: Text(c)))
//                   .toList(),
//               decoration: const InputDecoration(
//                 labelText: "Country/Region",
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedCountry = value!;
//                 });
//               },
//             ),
//
//             const SizedBox(height: 30),
//
//             // ---------------- SAVE BUTTON ----------------
//             SizedBox(
//               width: double.infinity,
//               height: 55,
//               child: ElevatedButton(
//                 onPressed: () {
//                   // handle save
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Changes Saved")),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1D2550),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 child: const Text(
//                   "Save changes",
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final picker = ImagePicker();

  String? _profileImage;

  // Initialize controllers without default text here
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(
    text: "********",
  ); // Keep as placeholder
  final TextEditingController _dobController = TextEditingController();

  String _selectedCountry = "Ghana"; // Default to Ghana
  final List<String> _countries = ["Ghana", "Nigeria", "Kenya", "South Africa"];

  @override
  void initState() {
    super.initState();
    // Fetch data from AppState and initialize controllers
    // Use `listen: false` in initState to prevent unnecessary rebuilds
    final appState = Provider.of<AppState>(context, listen: false);

    // Set the text for the name and email controllers
    _nameController.text = appState.loggedInUserName;
    _emailController.text = appState.loggedInEmail;
  }

  Future<void> _pickProfileImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      if (!mounted) return;
      setState(() {
        _profileImage = img.path;
      });
    }
  }

  Future<void> _selectDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ---------------- PROFILE IMAGE ----------------
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60, // Reduced radius for a cleaner look
                    backgroundImage: _profileImage != null
                        ? FileImage(File(_profileImage!))
                        : const AssetImage("assets/images/profile_1.jpg")
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: InkWell(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.camera_alt, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ---------------- TEXT FIELDS ----------------
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _emailController,
              readOnly:
                  true, // Make email read-only as it's the login identifier
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF0F0F0),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                // Add an icon to indicate this is a placeholder/action
                suffixIcon: Icon(Icons.edit_outlined),
              ),
              onTap: () {
                // You can add logic here to navigate to a "Change Password" screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Navigate to Change Password screen."),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),

            // ---------------- DOB PICKER ----------------
            TextField(
              controller: _dobController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Date of Birth",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_month),
              ),
              onTap: _selectDOB,
            ),
            const SizedBox(height: 15),

            // ---------------- COUNTRY DROPDOWN ----------------
            DropdownButtonFormField(
              value: _selectedCountry,
              items: _countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              decoration: const InputDecoration(
                labelText: "Country/Region",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            // ---------------- SAVE BUTTON ----------------
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // handle save
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Changes Saved")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D2550),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save changes",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
