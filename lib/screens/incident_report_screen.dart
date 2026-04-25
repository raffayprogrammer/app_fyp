import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../services/priority_classifier.dart';
import '../services/face_service.dart';
import '../services/face_blur_service.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'location_picker_screen.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  static const String _imgbbApiKey = String.fromEnvironment(
    'IMGBB_API_KEY',
    defaultValue: '3bf75075acddf4b14502a0d9908aef85',
  );

  Future<String?> uploadToImgBB(XFile imageFile) async {
    try {
      String url = 'https://api.imgbb.com/1/upload?key=$_imgbbApiKey';

      final bytes = await imageFile.readAsBytes();
      FormData formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: imageFile.name),
      });

      Response response = await Dio().post(url, data: formData);

      if (response.statusCode == 200) {
        return response.data['data']['url'];
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  final StorageService _storage = StorageService();
  bool _isUploading = false;
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Selected values
  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<XFile> _selectedImages = [];
  XFile? _verificationSelfie;
  String? _selfieStatus;
  bool _isAnonymous = false;
  bool _isLoading = false;
  // Map-picked coordinates (overrides current GPS if user explicitly picked).
  double? _pickedLatitude;
  double? _pickedLongitude;

  // Categories for dropdown - FIXED ICONS (removed 'skull')
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Murder', 'icon': Iconsax.danger, 'color': Colors.red},
    {'name': 'Snatching', 'icon': Iconsax.money, 'color': Colors.orange},
    {'name': 'Harassment', 'icon': Iconsax.warning_2, 'color': Colors.purple},
    {'name': 'Corruption', 'icon': Iconsax.money_tick, 'color': Colors.brown},
    {'name': 'Robbery', 'icon': Iconsax.lock, 'color': Colors.deepOrange},
    {'name': 'Theft', 'icon': Iconsax.box_remove, 'color': Colors.blueGrey},
    {'name': 'Assault', 'icon': Iconsax.man, 'color': Colors.redAccent},
    {'name': 'Fraud', 'icon': Iconsax.security_card, 'color': Colors.teal},
    {'name': 'Traffic Violation', 'icon': Iconsax.car, 'color': Colors.indigo},
    {'name': 'Other', 'icon': Iconsax.more, 'color': Colors.grey},
  ];

  // Image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Pick date
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Pick time
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images != null) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Remove image from list
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Capture a verification selfie and run ML Kit face detection on it.
  Future<void> _pickVerificationSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _selfieStatus = 'Checking selfie…');

      final result = await FaceService.verifyFace(File(image.path));

      setState(() {
        if (result.verified) {
          _verificationSelfie = image;
          _selfieStatus = '✅ ${result.reason}';
        } else {
          _verificationSelfie = null;
          _selfieStatus = '❌ ${result.reason}';
        }
      });
    } catch (e) {
      setState(() => _selfieStatus = '❌ Error: $e');
    }
  }

  Widget _imagePreview(XFile xfile) {
    if (kIsWeb) {
      return Image.network(xfile.path, fit: BoxFit.cover);
    }
    return Image.file(File(xfile.path), fit: BoxFit.cover);
  }

  // Submit report
  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Verified (non-anonymous) reports require a face-checked selfie.
      if (!_isAnonymous && _verificationSelfie == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Take a verification selfie before submitting, or toggle Anonymous.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not logged in');

        // Use map-picked coordinates if the user picked one; otherwise fall
        // back to the device's current GPS reading.
        double latitude;
        double longitude;
        if (_pickedLatitude != null && _pickedLongitude != null) {
          latitude = _pickedLatitude!;
          longitude = _pickedLongitude!;
        } else {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          latitude = position.latitude;
          longitude = position.longitude;
        }

        // UPLOAD IMAGES TO CLOUDINARY.
        // If the report is anonymous, auto-blur any detected faces before
        // uploading so the reporter's identity (and any bystanders) stay hidden.
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          for (XFile image in _selectedImages) {
            XFile toUpload = image;
            if (_isAnonymous) {
              toUpload = await FaceBlurService.blurFaces(image);
            }
            String? url = await uploadToImgBB(toUpload);
            if (url != null) {
              imageUrls.add(url);
            }
          }
        }

        // Upload verification selfie if provided.
        String? verificationSelfieUrl;
        if (_verificationSelfie != null) {
          verificationSelfieUrl = await uploadToImgBB(_verificationSelfie!);
        }

        final priority = PriorityClassifier.classify(
          category: _selectedCategory ?? 'Other',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        // Save to Firestore
        await FirebaseFirestore.instance.collection('reports').add({
          'userId': user.uid,
          'userEmail': user.email,
          'category': _selectedCategory,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'latitude': latitude,
          'longitude': longitude,
          'address': _locationController.text.trim(),
          'date': _selectedDate != null
              ? Timestamp.fromDate(_selectedDate!)
              : null,
          'time': _selectedTime?.format(context) ?? '',
          'isAnonymous': _isAnonymous,
          'images': imageUrls,
          'verificationSelfieUrl': verificationSelfieUrl,
          'verified': verificationSelfieUrl != null,
          'status': 'pending',
          'priority': priority,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report submitted!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedDate = null;
          _selectedTime = null;
          _selectedImages.clear();
          _verificationSelfie = null;
          _selfieStatus = null;
          _pickedLatitude = null;
          _pickedLongitude = null;
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Anonymous toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAnonymous ? Iconsax.eye_slash : Iconsax.eye,
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Report Anonymously',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value;
                          });
                        },
                        activeColor: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Category Selection
                      const Text(
                        'Select Incident Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Categories grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected =
                              _selectedCategory == category['name'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category['name'];
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? category['color'].withOpacity(0.2)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected
                                      ? category['color']
                                      : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    category['icon'],
                                    color: isSelected
                                        ? category['color']
                                        : Colors.grey.shade600,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    category['name'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? category['color']
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Incident Title',
                          prefixIcon: const Icon(
                            Iconsax.edit,
                            color: Color(0xFF2563EB),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Brief title of the incident',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Date and Time Row
                      Row(
                        children: [
                          // Date
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Iconsax.calendar,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            _selectedDate == null
                                                ? 'Select date'
                                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Time
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Iconsax.clock,
                                      color: Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Time',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            _selectedTime == null
                                                ? 'Select time'
                                                : _selectedTime!.format(
                                                    context,
                                                  ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(
                            Iconsax.location,
                            color: Color(0xFF2563EB),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Iconsax.map,
                              color: Color(0xFF2563EB),
                            ),
                            onPressed: () async {
                              final result =
                                  await Navigator.push<LocationPickerResult>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LocationPickerScreen(
                                    initialPosition: _pickedLatitude != null
                                        ? LatLng(
                                            _pickedLatitude!,
                                            _pickedLongitude!,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _pickedLatitude = result.latitude;
                                  _pickedLongitude = result.longitude;
                                  _locationController.text = result.address;
                                });
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Enter location or pick from map',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Incident Description',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 50),
                            child: Icon(Iconsax.note, color: Color(0xFF2563EB)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText:
                              'Provide detailed description of the incident...',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          if (value.length < 20) {
                            return 'Description must be at least 20 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Media Upload Section
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.gallery,
                                  color: Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Upload Evidence',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Optional',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Upload photos or videos as evidence.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Image picker buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _takePhoto,
                                    icon: const Icon(Iconsax.camera),
                                    label: const Text('Camera'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(Iconsax.gallery),
                                    label: const Text('Gallery'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Selected images grid
                      if (_selectedImages.isNotEmpty) ...[
                        const Text(
                          'Selected Images',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _imagePreview(_selectedImages[index]),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],

                      const SizedBox(height: 20),

                      // Verification selfie (required unless anonymous)
                      if (!_isAnonymous) ...[
                        Row(
                          children: [
                            const Icon(Iconsax.user_tick, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Verification Selfie',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '(required)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_verificationSelfie != null)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 70,
                                height: 70,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _imagePreview(_verificationSelfie!),
                                ),
                              ),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickVerificationSelfie,
                                icon: const Icon(Iconsax.camera),
                                label: Text(
                                  _verificationSelfie == null
                                      ? 'Take Selfie'
                                      : 'Retake Selfie',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selfieStatus != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _selfieStatus!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _selfieStatus!.startsWith('✅')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 10),

                      // Submit button
                      CustomButton(
                        text: 'Submit Report',
                        onPressed: _submitReport,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 20),

                      // Privacy note
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.shield_tick,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your identity is protected.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 15),
                        Text('Submitting report...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
