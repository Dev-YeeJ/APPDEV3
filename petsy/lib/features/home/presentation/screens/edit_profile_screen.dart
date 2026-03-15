import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Receive existing data

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  // Image Picker
  File? _newImage;
  final picker = ImagePicker();
  String? _currentBase64Image;

  // Colors
  final Color _petsyGreen = const Color(0xFF339967);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _lightGray = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    // Pre-fill the text fields with the user's current data
    _firstNameController = TextEditingController(
      text: widget.userData['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.userData['lastName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
    _currentBase64Image = widget.userData['base64Image'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
    }
  }

  Future<String?> _imageToBase64() async {
    if (_newImage == null) return null;
    try {
      final bytes = await _newImage!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Convert new image if selected
        String? newBase64Image = await _imageToBase64();

        // Update Firestore
        Map<String, dynamic> updates = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
        };

        if (newBase64Image != null) {
          updates['base64Image'] = newBase64Image;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updates);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Profile updated successfully!"),
              backgroundColor: _petsyGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Go back to profile page
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _petsyNavy),
        title: Text(
          "Edit Profile",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- AVATAR PICKER ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _petsyGreen, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _newImage != null
                              ? FileImage(_newImage!) as ImageProvider
                              : (_currentBase64Image != null
                                    ? MemoryImage(
                                        base64Decode(_currentBase64Image!),
                                      )
                                    : null),
                          child:
                              (_newImage == null && _currentBase64Image == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _petsyNavy,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tap to change photo",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 30),

              // --- FORM FIELDS ---
              _buildTextField(
                "First Name",
                Icons.person_outline,
                _firstNameController,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                "Last Name",
                Icons.person_outline,
                _lastNameController,
              ),
              const SizedBox(height: 15),

              _buildTextField(
                "Phone Number",
                Icons.phone_android,
                _phoneController,
                isPhone: true,
              ),

              const SizedBox(height: 40),

              // --- SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _petsyGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Save Changes",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  // Custom modern text field widget
  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          validator: (value) =>
              value!.isEmpty ? "This field cannot be empty" : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _petsyGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
