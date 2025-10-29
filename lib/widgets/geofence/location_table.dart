import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class LocationTable extends StatelessWidget {
  final List<Map<String, dynamic>> locations;

  const LocationTable({Key? key, required this.locations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No location records for today',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.resolveWith<Color?>((states) {
            return AppTheme.backgroundColor;
          }),
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Latitude')),
            DataColumn(label: Text('Longitude')),
            DataColumn(label: Text('Source')),
          ],
          rows: locations.map((loc) {
            // Use time field directly if available, otherwise extract from date/createdAt
            String time;
            if (loc['time'] != null && loc['time'].toString().isNotEmpty) {
              time = loc['time'].toString();
            } else {
              final dateStr = (loc['date'] ?? loc['createdAt'] ?? '')
                  .toString();
              time = _extractTime(dateStr);
            }
            final lat = (loc['lat'] ?? loc['latitude'] ?? '').toString();
            final lon = (loc['lon'] ?? loc['longitude'] ?? '').toString();
            final source =
                (loc['source'] ?? loc['provider'] ?? loc['inOut'] ?? 'GPS')
                    .toString();
            return DataRow(
              cells: [
                DataCell(Text(time)),
                DataCell(Text(lat)),
                DataCell(Text(lon)),
                DataCell(Text(source)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _extractTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '--:--:--';
    try {
      final dt = DateTime.tryParse(
        dateTimeStr.contains(' ')
            ? dateTimeStr.replaceFirst(' ', 'T')
            : dateTimeStr,
      );
      if (dt == null) return dateTimeStr;
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final ss = dt.second.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    } catch (_) {
      return dateTimeStr;
    }
  }
}
