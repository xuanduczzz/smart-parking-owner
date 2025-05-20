import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_view/photo_view.dart';
import '../../blocs/parking_lot/parking_lot_bloc.dart';
import '../../blocs/parking_lot/parking_lot_event.dart';
import '../../blocs/parking_lot/parking_lot_state.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'enter_slots_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class AddParkingLotScreen extends StatefulWidget {
  final bool isEditing;
  final String? docId;
  final Map<String, dynamic>? initialData;

  const AddParkingLotScreen({
    Key? key,
    this.isEditing = false,
    this.docId,
    this.initialData,
  }) : super(key: key);

  @override
  State<AddParkingLotScreen> createState() => _AddParkingLotScreenState();
}

class _AddParkingLotScreenState extends State<AddParkingLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  List<File> _imageFiles = [];
  List<File> _mapFiles = [];
  List<String> _existingImageUrls = [];
  List<String> _existingMapUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.docId != null) {
      _loadParkingLotData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadParkingLotData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('parking_lots')
          .doc(widget.docId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final location = data['location'];
        setState(() {
          _nameController.text = data['name'] ?? '';
          _addressController.text = data['address'] ?? '';
          _priceController.text = (data['pricePerHour'] ?? 0).toString();
          _latController.text = location != null ? location.latitude.toString() : '';
          _lngController.text = location != null ? location.longitude.toString() : '';
          _existingImageUrls = List<String>.from(data['imageUrl'] ?? []);
          _existingMapUrls = List<String>.from(data['parkingLotMap'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickImages(bool isMap) async {
    final picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        if (isMap) {
          _mapFiles.addAll(pickedFiles.map((e) => File(e.path)));
        } else {
          _imageFiles.addAll(pickedFiles.map((e) => File(e.path)));
        }
      });
    }
  }

  void _showImageGallery(BuildContext context, List<File> files, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: double.infinity,
          height: 400,
          child: PhotoViewGallery.builder(
            itemCount: files.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(files[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _imagePreview(List<File> files, List<String> existingUrls, void Function(int) onRemove, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
        const SizedBox(height: 8),
        if (existingUrls.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: existingUrls.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(existingUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          existingUrls.removeAt(index);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (files.isEmpty && existingUrls.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Chưa chọn ảnh', style: GoogleFonts.montserrat(color: Colors.grey)),
          )
        else if (files.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              itemBuilder: (context, index) => Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showImageGallery(context, files, index),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(files[index], width: 100, height: 100, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => onRemove(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ParkingLotBloc(CloudinaryPublic('dqnbclzi5', 'avatar_img', cache: false)),
      child: BlocListener<ParkingLotBloc, ParkingLotState>(
        listener: (context, state) {
          if (state is ParkingLotSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('save_parking_lot_success'))));
          } else if (state is ParkingLotError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.isEditing ? tr('edit_parking_lot') : tr('add_parking_lot')),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: tr('parking_lot_name'),
                                  prefixIcon: const Icon(Icons.local_parking),
                                ),
                                style: GoogleFonts.montserrat(fontSize: 16),
                                validator: (v) => v == null || v.isEmpty ? tr('enter_parking_lot_name') : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: tr('address'),
                                  prefixIcon: const Icon(Icons.location_on),
                                ),
                                style: GoogleFonts.montserrat(fontSize: 16),
                                validator: (v) => v == null || v.isEmpty ? tr('enter_address') : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: tr('price_per_hour'),
                                  prefixIcon: const Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.montserrat(fontSize: 16),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return tr('enter_price_per_hour');
                                  if (double.tryParse(v) == null) return tr('price_per_hour_must_be_number');
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latController,
                                      decoration: InputDecoration(
                                        labelText: tr('latitude'),
                                        prefixIcon: Icon(Icons.my_location),
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.montserrat(fontSize: 16),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return tr('enter_latitude');
                                        if (double.tryParse(v) == null) return tr('latitude_must_be_number');
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lngController,
                                      decoration: InputDecoration(
                                        labelText: tr('longitude'),
                                        prefixIcon: Icon(Icons.my_location),
                                      ),
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.montserrat(fontSize: 16),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return tr('enter_longitude');
                                        if (double.tryParse(v) == null) return tr('longitude_must_be_number');
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _imagePreview(_imageFiles, _existingImageUrls, (i) {
                                setState(() => _imageFiles.removeAt(i));
                              }, tr('parking_images')),
                              TextButton.icon(
                                onPressed: () => _pickImages(false),
                                icon: const Icon(Icons.photo_library, color: Colors.blue),
                                label: Text(tr('select_parking_images'), style: GoogleFonts.montserrat(color: Colors.blue)),
                              ),
                              const SizedBox(height: 24),

                              _imagePreview(_mapFiles, _existingMapUrls, (i) {
                                setState(() => _mapFiles.removeAt(i));
                              }, tr('select_map_images')),
                              TextButton.icon(
                                onPressed: () => _pickImages(true),
                                icon: const Icon(Icons.map, color: Colors.blue),
                                label: Text(tr('select_map_images'), style: GoogleFonts.montserrat(color: Colors.blue)),
                              ),
                              const SizedBox(height: 32),
                              BlocBuilder<ParkingLotBloc, ParkingLotState>(
                                builder: (context, state) {
                                  final isLoading = state is ParkingLotLoading;
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              if (!_formKey.currentState!.validate()) return;
                                              if (_imageFiles.isEmpty && _existingImageUrls.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('must_select_at_least_one_parking_image'))));
                                                return;
                                              }
                                              if (_mapFiles.isEmpty && _existingMapUrls.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('must_select_at_least_one_map_image'))));
                                                return;
                                              }
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BlocProvider.value(
                                                    value: context.read<ParkingLotBloc>(),
                                                    child: EnterSlotsScreen(
                                                      isEditing: widget.isEditing,
                                                      docId: widget.docId,
                                                      name: _nameController.text,
                                                      address: _addressController.text,
                                                      pricePerHour: double.parse(_priceController.text),
                                                      lat: double.parse(_latController.text),
                                                      lng: double.parse(_lngController.text),
                                                      imageFiles: _imageFiles,
                                                      mapFiles: _mapFiles,
                                                      existingImageUrls: _existingImageUrls,
                                                      existingMapUrls: _existingMapUrls,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                      label: isLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : Text(tr('continue'), style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
} 