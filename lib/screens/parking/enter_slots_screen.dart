import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/parking_lot/parking_lot_bloc.dart';
import '../../blocs/parking_lot/parking_lot_event.dart';
import '../../blocs/parking_lot/parking_lot_state.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class EnterSlotsScreen extends StatefulWidget {
  final bool isEditing;
  final String? docId;
  final String name;
  final String address;
  final double pricePerHour;
  final double lat;
  final double lng;
  final List<File> imageFiles;
  final List<File> mapFiles;
  final List<String> existingImageUrls;
  final List<String> existingMapUrls;

  const EnterSlotsScreen({
    Key? key,
    this.isEditing = false,
    this.docId,
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.lat,
    required this.lng,
    required this.imageFiles,
    required this.mapFiles,
    required this.existingImageUrls,
    required this.existingMapUrls,
  }) : super(key: key);

  @override
  State<EnterSlotsScreen> createState() => _EnterSlotsScreenState();
}

class _EnterSlotsScreenState extends State<EnterSlotsScreen> {
  final List<TextEditingController> _slotIdControllers = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.docId != null) {
      _loadExistingSlots();
    }
  }

  Future<void> _loadExistingSlots() async {
    final slotsSnapshot = await FirebaseFirestore.instance
        .collection('parking_lots')
        .doc(widget.docId)
        .collection('slots')
        .get();
    
    setState(() {
      for (var doc in slotsSnapshot.docs) {
        final data = doc.data();
        _slotIdControllers.add(TextEditingController(text: data['id']));
      }
    });
  }

  void _addSlot() {
    setState(() {
      _slotIdControllers.add(TextEditingController());
    });
  }

  void _removeSlot(int index) {
    setState(() {
      _slotIdControllers[index].dispose();
      _slotIdControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var c in _slotIdControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveAll() {
    if (_slotIdControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('must_add_at_least_one_slot'))));
      return;
    }
    for (var c in _slotIdControllers) {
      if (c.text.isEmpty || !RegExp(r'^[A-Z]').hasMatch(c.text)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('slot_id_must_uppercase'))));
        return;
      }
    }
    final slots = List.generate(_slotIdControllers.length, (i) => {
      'id': _slotIdControllers[i].text,
      'isBooked': false,
    });

    if (widget.isEditing && widget.docId != null) {
      context.read<ParkingLotBloc>().add(
        UpdateParkingLotWithSlotsEvent(
          docId: widget.docId!,
          name: widget.name,
          address: widget.address,
          pricePerHour: widget.pricePerHour,
          lat: widget.lat,
          lng: widget.lng,
          imageFiles: widget.imageFiles,
          mapFiles: widget.mapFiles,
          existingImageUrls: widget.existingImageUrls,
          existingMapUrls: widget.existingMapUrls,
          slots: slots,
        ),
      );
    } else {
      context.read<ParkingLotBloc>().add(
        SaveParkingLotWithSlotsEvent(
          name: widget.name,
          address: widget.address,
          pricePerHour: widget.pricePerHour,
          lat: widget.lat,
          lng: widget.lng,
          imageFiles: widget.imageFiles,
          mapFiles: widget.mapFiles,
          slots: slots,
          status: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ParkingLotBloc, ParkingLotState>(
      listener: (context, state) {
        if (state is ParkingLotSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('save_success'))));
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is ParkingLotError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(tr('enter_slot_info'))),
        body: Padding(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('slot_list'),
                            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue.shade800),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addSlot,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(tr('add_slot'), style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _slotIdControllers.length,
                        itemBuilder: (context, index) => Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _slotIdControllers[index],
                                    decoration: InputDecoration(
                                      labelText: tr('slot_id_hint'),
                                      prefixIcon: const Icon(Icons.event_seat),
                                    ),
                                    style: GoogleFonts.montserrat(fontSize: 16),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return tr('enter_slot_id');
                                      if (!RegExp(r'^[A-Z]').hasMatch(value)) return tr('slot_id_uppercase');
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeSlot(index),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<ParkingLotBloc, ParkingLotState>(
                      builder: (context, state) {
                        final isLoading = state is ParkingLotLoading;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save, color: Colors.white),
                            onPressed: isLoading ? null : _saveAll,
                            label: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(tr('save_all'), style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18)),
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
    );
  }
} 