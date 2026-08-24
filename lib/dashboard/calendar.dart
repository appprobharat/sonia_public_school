import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class StudentCalendarPage extends StatefulWidget {
  const StudentCalendarPage({super.key});

  @override
  State<StudentCalendarPage> createState() => _StudentCalendarPageState();
}

class _StudentCalendarPageState extends State<StudentCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> holidays = {
    DateTime(2026, 1, 1): ["🎉 New Year's Day"],
    DateTime(2026, 1, 14): ["🪁 Makar Sankranti"],
    DateTime(2026, 1, 26): ["🇮🇳 Republic Day"],

    DateTime(2026, 2, 15): ["🌸 Vasant Panchami"],
    DateTime(2026, 2, 26): ["🙏 Maha Shivratri"],

    DateTime(2026, 3, 4): ["🎨 Holi"],
    DateTime(2026, 3, 31): ["🌙 Eid-ul-Fitr"],

    DateTime(2026, 4, 2): ["🕉️ Ram Navami"],
    DateTime(2026, 4, 14): ["🎂 Dr. Ambedkar Jayanti"],
    DateTime(2026, 4, 18): ["✝️ Good Friday"],

    DateTime(2026, 5, 1): ["👷 Labour Day"],
    DateTime(2026, 5, 12): ["🌕 Buddha Purnima"],

    DateTime(2026, 6, 7): ["🐐 Eid-ul-Adha"],

    DateTime(2026, 7, 6): ["🚩 Muharram"],

    DateTime(2026, 8, 15): ["🇮🇳 Independence Day"],
    DateTime(2026, 8, 16): ["🎀 Raksha Bandhan"],
    DateTime(2026, 8, 27): ["🐘 Ganesh Chaturthi"],

    DateTime(2026, 9, 5): ["🌙 Eid-e-Milad"],

    DateTime(2026, 10, 2): ["🕊️ Gandhi Jayanti"],
    DateTime(2026, 10, 19): ["🌼 Dussehra"],
    DateTime(2026, 11, 8): ["🪔 Diwali"],
    DateTime(2026, 11, 9): ["🎆 Govardhan Puja"],
    DateTime(2026, 11, 11): ["👫 Bhai Dooj"],
    DateTime(2026, 11, 24): ["🙏 Guru Nanak Jayanti"],

    DateTime(2026, 12, 25): ["🎄 Christmas"],
  };
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDay = DateFormat('EEEE').format(today);
    final formattedDate = DateFormat('d MMMM yyyy').format(today);
    final selectedHoliday = _selectedDay == null
        ? <String>[]
        : holidays.entries
              .where((e) => isSameDay(e.key, _selectedDay!))
              .expand((e) => e.value)
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff1E40AF), Color(0xff2563EB), Color(0xff3B82F6)],
            ),
          ),
        ),
        title: const Text(
          "School Calendar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: .5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// TODAY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff1E40AF),
                    Color(0xff2563EB),
                    Color(0xff3B82F6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff2563EB).withOpacity(.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Today",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd').format(today),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(today).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            /// CALENDAR CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                eventLoader: (day) {
                  return holidays.entries
                      .where((e) => isSameDay(e.key, day))
                      .expand((e) => e.value)
                      .toList();
                },

                calendarFormat: CalendarFormat.month,

                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },

                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,

                  leftChevronIcon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xff2563EB),
                  ),

                  rightChevronIcon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xff2563EB),
                  ),

                  titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Color(0xff1E3A8A),
                  ),
                ),

                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),

                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,

                  defaultTextStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),

                  weekendTextStyle: const TextStyle(color: Colors.red),

                  todayDecoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    shape: BoxShape.circle,
                  ),

                  selectedDecoration: const BoxDecoration(
                    color: Color(0xff2563EB),
                    shape: BoxShape.circle,
                  ),

                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),

                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),

                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            if (_selectedDay != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blue.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: Color(0xff2563EB),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selected Date",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                            ).format(_selectedDay!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedHoliday.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    "🎉",
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedHoliday.first,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
