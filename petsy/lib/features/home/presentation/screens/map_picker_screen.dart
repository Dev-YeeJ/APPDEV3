import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// --- RPCMB IMPORT ---
import 'package:philippines_rpcmb/philippines_rpcmb.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();

  // Default location (Urdaneta City)
  LatLng _currentMapPosition = const LatLng(15.9758, 120.5707);

  // Manual Entry Controller (Only for Street now)
  final TextEditingController _streetController = TextEditingController();

  // Philippine Location Dropdown States
  Region? selectedRegion;
  Province? selectedProvince;
  Municipality? selectedMunicipality;
  String? selectedBarangay;

  bool _isLoading = false;
  bool _isSaving = false;

  final Color _petsyGreen = const Color(0xFF2B8C61);
  final Color _petsyNavy = const Color(0xFF003466);

  @override
  void initState() {
    super.initState();
    _getUserCurrentLocation();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- SMART STRING MATCHER ---
  // Helps match "Urdaneta City" from the Map to "Urdaneta" in the Dropdowns
  bool _isSmartMatch(String dbName, String geoName) {
    if (dbName.isEmpty || geoName.isEmpty) return false;

    // Clean both strings: lowercase, remove common words, remove spaces/punctuation
    String clean(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'(city|municipality|province|region|of|the)'), '')
        .replaceAll(RegExp(r'[^a-z]'), '');

    String c1 = clean(dbName);
    String c2 = clean(geoName);

    if (c1.isEmpty || c2.isEmpty) return false;
    return c1 == c2 || c1.contains(c2) || c2.contains(c1);
  }

  // 1. Get user's GPS Location
  Future<void> _getUserCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    _mapController.move(userLatLng, 16.0);
    _updateAddressFromLatLng(userLatLng);
  }

  // 2. Auto-fill Text Fields AND Dropdowns from Map Pin
  Future<void> _updateAddressFromLatLng(LatLng position) async {
    setState(() => _isLoading = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Extract Geocoding Data
        String geoStreet = place.street ?? "";
        String geoBarangay = place.subLocality ?? ""; // Often Barangay
        String geoCity = place.locality ?? ""; // Often City/Muni
        String geoProvince =
            place.subAdministrativeArea ?? ""; // Often Province
        String geoRegion = place.administrativeArea ?? ""; // Often Region

        // Variables to hold our matched objects
        Region? foundRegion;
        Province? foundProvince;
        Municipality? foundCity;
        String? foundBarangay;

        // Step A: Find matching Province (Best anchor point)
        for (var r in philippineRegions) {
          for (var p in r.provinces) {
            if (_isSmartMatch(p.name, geoProvince) ||
                _isSmartMatch(p.name, geoCity)) {
              foundRegion = r;
              foundProvince = p;
              break;
            }
          }
          if (foundProvince != null) break;
        }

        // Step B: If Region found but Province wasn't (Fallback)
        if (foundRegion == null && geoRegion.isNotEmpty) {
          for (var r in philippineRegions) {
            if (_isSmartMatch(r.regionName, geoRegion)) {
              foundRegion = r;
              break;
            }
          }
        }

        // Step C: Find Municipality inside the found Province
        if (foundProvince != null && geoCity.isNotEmpty) {
          for (var m in foundProvince.municipalities) {
            if (_isSmartMatch(m.name, geoCity)) {
              foundCity = m;
              break;
            }
          }
        }

        // Step D: Find Barangay inside the found Municipality
        if (foundCity != null && geoBarangay.isNotEmpty) {
          for (var b in foundCity.barangays) {
            if (_isSmartMatch(b, geoBarangay)) {
              foundBarangay = b;
              break;
            }
          }
        }

        // Step E: Update the State with everything we found!
        setState(() {
          _streetController.text = geoStreet;

          if (foundRegion != null) selectedRegion = foundRegion;
          if (foundProvince != null) selectedProvince = foundProvince;
          if (foundCity != null) selectedMunicipality = foundCity;
          if (foundBarangay != null) selectedBarangay = foundBarangay;

          _currentMapPosition = position;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                foundProvince != null
                    ? "Address Auto-filled from Pin!"
                    : "Pin recorded! Please select the rest of your address manually.",
              ),
              backgroundColor: _petsyGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not find address for this pin. Please select manually.",
            ),
          ),
        );
      }
    }
  }

  // 3. Save to Firebase
  Future<void> _saveLocation() async {
    if (selectedRegion == null ||
        selectedProvince == null ||
        selectedMunicipality == null ||
        selectedBarangay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all dropdown selections!"),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    String fullAddress = "";
    if (_streetController.text.trim().isNotEmpty) {
      fullAddress += "${_streetController.text.trim()}, ";
    }
    fullAddress +=
        "$selectedBarangay, ${selectedMunicipality!.name}, ${selectedProvince!.name}";

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'address': {
          'street': _streetController.text.trim(),
          'barangay': selectedBarangay,
          'city': selectedMunicipality!.name,
          'province': selectedProvince!.name,
          'region': selectedRegion!.regionName,
          'fullAddress': fullAddress,
          'latitude': _currentMapPosition.latitude,
          'longitude': _currentMapPosition.longitude,
        },
      }, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Set Delivery Address",
          style: GoogleFonts.inter(
            color: _petsyNavy,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: _petsyNavy),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- TOP HALF: THE MAP ---
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentMapPosition,
                    initialZoom: 15.0,
                    onPositionChanged: (MapCamera camera, bool hasGesture) {
                      _currentMapPosition = camera.center;
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.petsy',
                    ),
                  ],
                ),

                // Floating Pin in the center
                Padding(
                  padding: const EdgeInsets.only(bottom: 35),
                  child: Icon(Icons.location_on, color: _petsyGreen, size: 45),
                ),

                // GPS Target Button
                Positioned(
                  right: 15,
                  bottom: 15,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _getUserCurrentLocation,
                    child: Icon(Icons.my_location, color: _petsyNavy, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM HALF: MANUAL ENTRY FORM ---
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pin Location Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: _petsyGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () =>
                                  _updateAddressFromLatLng(_currentMapPosition),
                        icon: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.auto_awesome,
                                color: _petsyGreen,
                                size: 18,
                              ),
                        label: Text(
                          "Auto-fill from Map Pin",
                          style: GoogleFonts.inter(
                            color: _petsyGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "ADDRESS DETAILS",
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 1. Street Entry
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "House/Unit No., Street Name",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _streetController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5F6F8),
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
                              borderSide: BorderSide(
                                color: _petsyGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // 2. Region Dropdown
                    _buildDropdownLabel("Region"),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PhilippineRegionDropdownView(
                        onChanged: (Region? value) {
                          setState(() {
                            if (selectedRegion != value) {
                              selectedProvince = null;
                              selectedMunicipality = null;
                              selectedBarangay = null;
                            }
                            selectedRegion = value;
                          });
                        },
                        value: selectedRegion,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 3. Province Dropdown
                    _buildDropdownLabel("Province"),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PhilippineProvinceDropdownView(
                        provinces: selectedRegion?.provinces ?? [],
                        onChanged: (Province? value) {
                          setState(() {
                            if (selectedProvince != value) {
                              selectedMunicipality = null;
                              selectedBarangay = null;
                            }
                            selectedProvince = value;
                          });
                        },
                        value: selectedProvince,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 4. Municipality / City Dropdown
                    _buildDropdownLabel("Municipality / City"),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PhilippineMunicipalityDropdownView(
                        municipalities: selectedProvince?.municipalities ?? [],
                        onChanged: (value) {
                          setState(() {
                            if (selectedMunicipality != value) {
                              selectedBarangay = null;
                            }
                            selectedMunicipality = value;
                          });
                        },
                        value: selectedMunicipality,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 5. Barangay Dropdown
                    _buildDropdownLabel("Barangay"),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PhilippineBarangayDropdownView(
                        barangays: selectedMunicipality?.barangays ?? [],
                        onChanged: (value) {
                          setState(() {
                            selectedBarangay = value;
                          });
                        },
                        value: selectedBarangay,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _petsyGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveLocation,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Confirm Address",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for dropdown labels
  Widget _buildDropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
