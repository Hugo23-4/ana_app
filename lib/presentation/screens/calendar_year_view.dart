import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/event_model.dart';
import '../../../data/repositories/event_repository.dart';
import 'calendar_screen.dart';

class CalendarYearView extends StatefulWidget {
  const CalendarYearView({super.key});

  @override
  State<CalendarYearView> createState() => _CalendarYearViewState();
}

class _CalendarYearViewState extends State<CalendarYearView> {
  final EventRepository _eventRepo = EventRepository();
  final int year = DateTime.now().year;
  final Map<int, bool> _hasEvents = {};

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  void _loadEventData() {
    _eventRepo.getEvents().listen((allEvents) {
      final Map<int, bool> tempMap = {};
      for (var event in allEvents) {
        if (event.date.year == year) {
          tempMap[event.date.month] = true;
        }
      }
      setState(() => _hasEvents.addAll(tempMap));
    });
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => DateTime(year, i + 1, 1));

    return Scaffold(
      appBar: AppBar(
        title: Text('Vista Anual $year'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: 12,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final month = months[index];
            final monthName = DateFormat.MMM('es_ES').format(month).toUpperCase();
            final hasEvent = _hasEvents[month.month] ?? false;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CalendarScreen(initialFocusedDay: month),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: hasEvent ? Colors.indigo.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 1)),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    if (hasEvent)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
