import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Map<DateTime, List<Map<String, dynamic>>> _events;
  late List<Map<String, dynamic>> _selectedEvents;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedEvents = [];
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final eventDocs =
          await FirebaseFirestore.instance.collection('CalendarEvents').get();

      final Map<DateTime, List<Map<String, dynamic>>> eventMap = {};
      for (var doc in eventDocs.docs) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp).toDate();
        final endDate = (data['endDate'] as Timestamp).toDate();
        final eventTitle = data['title'] as String;
        final eventDescription = data['description'] as String;

        DateTime currentDay =
            DateTime(startDate.year, startDate.month, startDate.day);
        final endDay = DateTime(endDate.year, endDate.month, endDate.day);

        while (currentDay.isBefore(endDay) ||
            currentDay.isAtSameMomentAs(endDay)) {
          final normalizedEventDate =
              DateTime(currentDay.year, currentDay.month, currentDay.day);
          final eventList = eventMap[normalizedEventDate] ?? [];
          eventList.add({
            'title': eventTitle,
            'description': eventDescription,
          });
          eventMap[normalizedEventDate] = eventList;
          currentDay = currentDay.add(Duration(days: 1));
        }
      }

      setState(() {
        _events = eventMap;
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  List<dynamic> _getEventsIndicator(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] != null
        ? [true]
        : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            eventLoader: _getEventsIndicator,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _getEventsForDay(selectedDay);
              });
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? '',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          event['description'] ?? '',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
