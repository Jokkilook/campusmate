import 'package:auto_size_text/auto_size_text.dart';
import 'package:campusmate/models/schedule_data.dart';
import 'package:flutter/material.dart';

//시간표 출력하는 위젯. 매개변수로 유저의 시간표 데이터를 넣어줘야한다.
class ScheduleTable extends StatefulWidget {
  final ScheduleData scheduleData;
  final bool readOnly;

  const ScheduleTable(
      {super.key, required this.scheduleData, this.readOnly = false});

  @override
  State<ScheduleTable> createState() => _ScheduleTableState();
}

class _ScheduleTableState extends State<ScheduleTable> {
  var dayData = ["월", "화", "수", "목", "금"];
  var timeData = [
    " ",
    "08:00 ~ 09:00",
    "09:00 ~ 10:00",
    "10:00 ~ 11:00",
    "11:00 ~ 12:00",
    "12:00 ~ 13:00",
    "13:00 ~ 14:00",
    "14:00 ~ 15:00",
    "15:00 ~ 16:00",
    "16:00 ~ 17:00",
    "17:00 ~ 18:00",
    "18:00 ~ 19:00",
    "19:00 ~ 20:00",
  ];

  late List<Map<String, bool>> totalSchedule = [
    widget.scheduleData.schedule[0],
    widget.scheduleData.schedule[1],
    widget.scheduleData.schedule[2],
    widget.scheduleData.schedule[3],
    widget.scheduleData.schedule[4],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      foregroundDecoration: BoxDecoration(
          border: Border.all(width: 1.5, color: const Color(0xFFD2D2D2)),
          borderRadius: BorderRadius.circular(10)),
      decoration: BoxDecoration(
          border: Border.all(width: 1, color: const Color(0xFFD2D2D2)),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Column(
            children: [
              for (var time in timeData)
                Container(
                    width: 90,
                    height: 35,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          width: 0.5, color: const Color(0xFFD2D2D2)),
                    ),
                    child: Center(
                        child: AutoSizeText(
                      time,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    )))
            ],
          ),
          for (var day in totalSchedule)
            Expanded(
              flex: 8,
              child: Column(
                children: [
                  Container(
                      width: 1000,
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E9E9),
                        border: Border.all(
                            width: 0.5, color: const Color(0xFFD2D2D2)),
                      ),
                      child: Center(
                          child: Text(
                        day.keys.first.substring(0, 3),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ))),
                  for (var detail in day.entries)
                    GestureDetector(
                      onTap: widget.readOnly
                          ? null
                          : () {
                              day[detail.key] = !detail.value;
                              setState(() {});
                            },
                      child: Container(
                        width: 1000,
                        height: 35,
                        decoration: BoxDecoration(
                          color: detail.value
                              ? const Color(0xFFFAFAFA)
                              : const Color(0xFF2CB66B),
                          border: Border.all(
                              width: 0.5, color: const Color(0xFFD2D2D2)),
                        ),
                      ),
                    ),
                ],
              ),
            )
        ],
      ),
    );
  }
}
