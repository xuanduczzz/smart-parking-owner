import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingTimePickerWidget extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;

  const BookingTimePickerWidget({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.onDateChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text("Chọn ngày", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: TableCalendar(
            firstDay: DateTime.utc(2022, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            onDaySelected: (selected, _) => onDateChanged(selected),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
              selectedTextStyle: const TextStyle(color: Colors.white),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blue),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8),
          child: Text("Chọn giờ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            buildTimeBox(context, "Giờ bắt đầu", startTime, () {
              _showCustomTimePicker(context, onStartTimeChanged);
            }),
            const SizedBox(width: 12),
            buildTimeBox(context, "Giờ kết thúc", endTime, () {
              _showCustomTimePicker(context, onEndTimeChanged);
            }),
          ],
        ),
      ],
    );
  }

  Widget buildTimeBox(BuildContext context, String label, TimeOfDay time, VoidCallback onTap) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(time.format(context), style: const TextStyle(fontSize: 16)),
                  const Icon(Icons.access_time, size: 18, color: Colors.blueAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomTimePicker(BuildContext context, ValueChanged<TimeOfDay> onTimeSelected) {
    final timeSlots = _generateTimeSlots();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: 300,
        child: ListView.builder(
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final time = timeSlots[index];
            return ListTile(
              title: Text(time.format(context)),
              onTap: () {
                Navigator.pop(context);
                onTimeSelected(time);
              },
            );
          },
        ),
      ),
    );
  }

  List<TimeOfDay> _generateTimeSlots() {
    List<TimeOfDay> timeSlots = [];
    for (int hour = 6; hour <= 23; hour++) {
      timeSlots.add(TimeOfDay(hour: hour, minute: 0));
      timeSlots.add(TimeOfDay(hour: hour, minute: 30));
    }
    return timeSlots;
  }
}