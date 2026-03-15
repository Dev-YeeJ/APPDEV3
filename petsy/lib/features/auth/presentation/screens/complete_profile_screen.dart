import 'dart:io';
import 'dart:convert'; // NEW: For converting image to text
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Note: You can remove 'package:firebase_storage/firebase_storage.dart' since we aren't using it
import 'package:google_fonts/google_fonts.dart';
import 'sign_up_screen.dart';
import 'package:petsy/features/home/presentation/screens/profile_page.dart'; // NEW: Import the profile screen to navigate to after saving

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final picker = ImagePicker();

  Region? _region;
  Province? _province;
  Municipality? _municipality;
  String? _barangay;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  bool _isLoading = false;

  final Color _petsyGreen = const Color(0xFF339967);
  final Color _petsyNavy = const Color(0xFF003466);
  final Color _cardColor = const Color(0xFFE6E6E6);
  final Color _screenBg = const Color(0xFFF2F2F2);

  void _showModernToast(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : _petsyGreen,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      // CRITICAL: We must shrink the image to fit in Firestore (< 1MB limit)
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 50,
    );
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  // --- NEW: Convert Image to Text String ---
  Future<String?> _imageToBase64() async {
    if (_image == null) return null;
    try {
      final bytes = await _image!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Conversion failed: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showModernToast("Please fix the errors", isError: true);
      return;
    }

    if (_region == null ||
        _province == null ||
        _municipality == null ||
        _barangay == null) {
      _showModernToast("Please complete your address", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // 1. Convert Image to Text String (No Storage needed)
        String? base64Image = await _imageToBase64();

        // 2. Save EVERYTHING to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': {
            'region': _region?.regionName,
            'province': _province?.name,
            'city': _municipality?.name,
            'barangay': _barangay,
            'street': _streetController.text.trim(),
          },
          // We save the actual image data as a string here
          if (base64Image != null) 'base64Image': base64Image,
          'profileCompleted': true,
        });

        _showModernToast("Profile Saved!", isError: false);
        if (mounted) {
          // Use pushReplacement so they can't go 'back' to the edit form
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      }
    } catch (e) {
      _showModernToast("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Your existing layout code stays exactly the same)
    // Just ensure resizeToAvoidBottomInset is true
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;
    final double logoHeight = isSmallScreen ? 50 : 70;
    final double cardTopMargin = 45.0;
    const double fieldGap = 8.0;
    const double avatarRadius = 42.0;

    return Scaffold(
      backgroundColor: _screenBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GradientWavePainter(
                colorStart: _petsyGreen,
                colorEnd: _petsyNavy,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/petsylogo.png',
                      height: logoHeight,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.pets, color: _petsyGreen),
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: cardTopMargin),
                          padding: const EdgeInsets.fromLTRB(16, 55, 16, 20),
                          decoration: BoxDecoration(
                            color: _cardColor.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Edit Your Information",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                FloatingValidatorField(
                                  hint: "First Name",
                                  icon: Icons.person_outline,
                                  controller: _firstNameController,
                                  validator: (v) => v!.isEmpty ? "Req" : null,
                                ),
                                const SizedBox(height: fieldGap),
                                FloatingValidatorField(
                                  hint: "Last Name",
                                  icon: Icons.person_outline,
                                  controller: _lastNameController,
                                  validator: (v) => v!.isEmpty ? "Req" : null,
                                ),
                                const SizedBox(height: fieldGap),
                                FloatingValidatorField(
                                  hint: "09123456789",
                                  icon: Icons.phone_android,
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      v!.length < 11 ? "Invalid" : null,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Shipping Address",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildStyledDropdown(
                                  child: PhilippineRegionDropdownView(
                                    value: _region,
                                    onChanged: (v) => setState(() {
                                      if (_region != v) {
                                        _province = null;
                                        _municipality = null;
                                        _barangay = null;
                                      }
                                      _region = v;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: fieldGap),
                                _buildStyledDropdown(
                                  child: PhilippineProvinceDropdownView(
                                    provinces: _region?.provinces ?? [],
                                    value: _province,
                                    onChanged: (v) => setState(() {
                                      if (_province != v) {
                                        _municipality = null;
                                        _barangay = null;
                                      }
                                      _province = v;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: fieldGap),
                                _buildStyledDropdown(
                                  child: PhilippineMunicipalityDropdownView(
                                    municipalities:
                                        _province?.municipalities ?? [],
                                    value: _municipality,
                                    onChanged: (v) => setState(() {
                                      if (_municipality != v) _barangay = null;
                                      _municipality = v;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: fieldGap),
                                _buildStyledDropdown(
                                  child: PhilippineBarangayDropdownView(
                                    barangays: _municipality?.barangays ?? [],
                                    value: _barangay,
                                    onChanged: (v) =>
                                        setState(() => _barangay = v),
                                  ),
                                ),
                                const SizedBox(height: fieldGap),
                                FloatingValidatorField(
                                  hint: "House No. / Street",
                                  icon: Icons.home_work_outlined,
                                  controller: _streetController,
                                  validator: (v) => v!.isEmpty ? "Req" : null,
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _petsyGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _saveProfile,
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            "CREATE ACCOUNT",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: _image != null
                                        ? FileImage(_image!)
                                        : null,
                                    child: _image == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 45,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF003466),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDropdown({required Widget child}) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }
}
