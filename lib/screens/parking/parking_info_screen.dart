import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/parking_lot/parking_lot_bloc.dart';
import '../../blocs/parking_lot/parking_lot_event.dart';
import '../../blocs/parking_lot/parking_lot_state.dart';
import '../../widgets/custom_date_picker.dart';
import '../../widgets/car_dropdown.dart';
import 'add_parking_lot_screen.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingInfoScreen extends StatefulWidget {
  const ParkingInfoScreen({Key? key}) : super(key: key);

  @override
  State<ParkingInfoScreen> createState() => _ParkingInfoScreenState();
}

class _ParkingInfoScreenState extends State<ParkingInfoScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String? selectedCarType;

  @override
  void initState() {
    super.initState();
    context.read<ParkingLotBloc>().add(LoadParkingLotsEvent());
  }

  Widget _buildAvailableSlots(List<Map<String, dynamic>> slots) {
    final availableSlots = slots.where((slot) => !slot['isBooked']).toList();
    print('Available slots after filtering: ${availableSlots.length}');

    if (availableSlots.isEmpty) {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.no_meeting_room, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                tr('no_available_slots'),
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_parking, size: 20, color: Colors.blue.shade800),
                const SizedBox(width: 12),
                Text(
                  tr('available_slots'),
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${tr('total_available')}: ${availableSlots.length}',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                final slot = availableSlots[index];
                print('Rendering slot: ${slot['id']}');
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade100,
                        Colors.green.shade50,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade100.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // TODO: Handle slot selection
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_parking,
                              size: 20,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot['id'] ?? '',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('parking_info')),
      ),
      body: BlocConsumer<ParkingLotBloc, ParkingLotState>(
        listener: (context, state) {
          print('State changed: $state');
          if (state is ParkingLotError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          print('Building UI with state: $state');
          if (state is ParkingLotLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is ParkingLotLoaded) {
            print('ParkingLotLoaded: ${state.parkingLots.docs.length} lots');
            if (state.parkingLots.docs.isEmpty) {
              return Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddParkingLotScreen()),
                    );
                  },
                  label: Text(tr('add_parking_lot'), style: TextStyle(fontSize: 18)),
                ),
              );
            }

            final doc = state.parkingLots.docs.first;
            final data = doc.data() as Map<String, dynamic>;
            print('Parking lot data: $data');
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['name'] ?? '',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                                  tooltip: tr('edit_parking_lot'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider.value(
                                          value: context.read<ParkingLotBloc>(),
                                          child: AddParkingLotScreen(
                                            isEditing: true,
                                            docId: doc.id,
                                            initialData: data,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['address'] ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.attach_money, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  tr('price_per_hour') + ': ',
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, color: Colors.blue.shade700),
                                ),
                                Text(
                                  '${data['pricePerHour'] ?? ''} VNĐ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.event_seat, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  tr('total_slot') + ': ',
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, color: Colors.blue.shade700),
                                ),
                                FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('parking_lots')
                                      .doc(doc.id)
                                      .collection('slots')
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Text(
                                        '${snapshot.data!.docs.length}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      );
                                    }
                                    return const Text('0');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (data['status'] == false)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.block, color: Colors.red.shade800, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      tr('parking_lot_locked'),
                                      style: GoogleFonts.montserrat(
                                        color: Colors.red.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (data['status'] == true) ...[
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('check_availability'),
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              BookingTimePickerWidget(
                                selectedDate: selectedDate,
                                startTime: startTime,
                                endTime: endTime,
                                onDateChanged: (date) => setState(() => selectedDate = date),
                                onStartTimeChanged: (time) => setState(() => startTime = time),
                                onEndTimeChanged: (time) => setState(() => endTime = time),
                              ),
                              const SizedBox(height: 16),
                              CarDropdown(
                                onChanged: (value) => setState(() => selectedCarType = value),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.search, color: Colors.white),
                                  onPressed: () {
                                    if (selectedCarType == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(tr('please_select_car_type'))),
                                      );
                                      return;
                                    }
                                    print('Checking availability for:');
                                    print('LotId: ${doc.id}');
                                    print('VehicleType: $selectedCarType');
                                    print('StartTime: $startTime');
                                    print('EndTime: $endTime');
                                    context.read<ParkingLotBloc>().add(
                                      CheckAvailableSlotsEvent(
                                        lotId: doc.id,
                                        vehicleType: selectedCarType!,
                                        startTime: DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          selectedDate.day,
                                          startTime.hour,
                                          startTime.minute,
                                        ),
                                        endTime: DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          selectedDate.day,
                                          endTime.hour,
                                          endTime.minute,
                                        ),
                                      ),
                                    );
                                  },
                                  label: Text(
                                    tr('check_availability'),
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<ParkingLotBloc, ParkingLotState>(
                        buildWhen: (previous, current) => current is AvailableSlotsLoaded || current is ParkingLotLoading,
                        builder: (context, state) {
                          print('Building available slots with state: $state');
                          if (state is ParkingLotLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (state is AvailableSlotsLoaded) {
                            print('AvailableSlotsLoaded: ${state.slots.length} slots');
                            return _buildAvailableSlots(state.slots);
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          if (state is AvailableSlotsLoaded) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildAvailableSlots(state.slots),
              ),
            );
          }

          if (state is ParkingLotError) {
            return Center(child: Text(state.message));
          }

          return const Center(child: Text('No data available'));
        },
      ),
    );
  }
} 