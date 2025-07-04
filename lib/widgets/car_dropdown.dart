import 'package:flutter/material.dart';

class CarDropdown extends StatefulWidget {
  final Function(String?)? onChanged;
  final String? value;

  const CarDropdown({
    Key? key, 
    this.onChanged,
    this.value,
  }) : super(key: key);

  @override
  _CarDropdownState createState() => _CarDropdownState();
}

class _CarDropdownState extends State<CarDropdown> {
  final List<String> carTypes = [
    'Xe con 4-5 chỗ',
    'Xe con 7 chỗ',
    'Xe 16 chỗ',
    'Xe 29 chỗ',
    'Xe giường nằm',
    'Xe tải 1-6 tấn',
    'Xe tải 6-10 tấn',
    'Xe tải trên 10 tấn',
    'Xe container không thùng',
    'Xe container có thùng',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Chọn loại xe',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: widget.value,
      isExpanded: true,
      items: carTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      },
    );
  }
}
