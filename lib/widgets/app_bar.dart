import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_data/time_point/time_point.dart';
import '../providers/time_data_provider.dart';

final appBarPro = Provider((ref) {
  final time = ref.watch(timeDataPro);
  Map<String, dynamic> appBar = {};
  final dayNum = time.todayEntry.dt.difference(time.dayEntries.first.dt).inDays;
  appBar['day'] = dayNum;
  appBar['date'] = DateFormat('EEEE, MMMM d, y').format(time.todayEntry.dt);
  appBar['isTracking'] = time.todayEntry.durPoint.typ == TimePointTyp.resume;
  return appBar;
});

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current time entry data
    final appBarProvider = ref.watch(appBarPro);
    final dayNum = appBarProvider['day'];
    final date = appBarProvider['date'];
    final isTracking = appBarProvider['isTracking'];

    // Set background color based on tracking state
    final backgroundColor = isTracking ? Colors.red : Colors.grey[200];
    final textColor = isTracking ? Colors.white : Colors.black;

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 2,
      title: Row(
        children: [
          // Day number display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: textColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'DAY $dayNum',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Date display
          Text(
            date,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 14,
              color: textColor,
            ),
          ),
        ],
      ),
      actions: [
        // Tracking toggle button
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            onPressed: () {
              // Toggle tracking state
              ref.read(timeDataPro.notifier).handelAddEvent();
            },
            icon: Icon(
              isTracking ? Icons.stop : Icons.play_arrow,
              color: textColor,
            ),
            tooltip: isTracking ? 'Stop tracking' : 'Start tracking',
          ),
        ),
        // Status indicator
        // if (isTracking)
        //   const Padding(
        //     padding: EdgeInsets.only(right: 16.0),
        //     child: Icon(Icons.fiber_manual_record, color: Colors.white),
        //   ),
      ],
    );
  }
}
