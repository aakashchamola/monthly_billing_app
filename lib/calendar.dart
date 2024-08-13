import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:monthly_bills_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class BillCalendarScreen extends StatefulWidget {
  final Bill bill;
  final List<Bill> bills;
  final VoidCallback updateTotalValue;

  BillCalendarScreen({
    required this.bill,
    required this.bills,
    required this.updateTotalValue,
  });

  // static void updateCalendar(Bill bill) {
  //   // Notify the BillCalendarScreen to update its state
  //   // _BillCalendarScreenState? currentState = BillCalendarScreen._currentState;
  //   // currentState?.updateCalendar(bill);
  // }

  static _BillCalendarScreenState? _currentState;

  @override
  _BillCalendarScreenState createState() {
    _currentState = _BillCalendarScreenState();
    return _currentState!;
  }
}

class _BillCalendarScreenState extends State<BillCalendarScreen> {
  // double totalValue = 0.0;
  double _calendarTotalValue = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTotalValue();
    _calculateCalendarTotalValue();
    // updateCalendar(widget.bill);
    // widget.updateTotalValue();
  }

  // void updateCalendar(Bill bill) {
  //   setState(() {
  //     // Force the state update to reflect changes
  //     widget.bill.totalValue = bill.totalValue;
  //     widget.bill.issueDates = List.from(bill.issueDates);
  //     widget.bill.billsPerDate = Map.from(bill.billsPerDate);
  //   });
  // }

  void _updateTotalValue() {
    setState(() {
      _calendarTotalValue = widget.bill.totalValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar - ${widget.bill.name}'),
      ),
      body: Column(
        children: [
          Text(
            'Total Value: Rs. ${_calendarTotalValue.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18),
          ),
          Expanded(
            child: TableCalendar(
              focusedDay: DateTime.now(),
              firstDay:
                  DateTime(DateTime.now().year, DateTime.now().month - 1, 1),
              lastDay:
                  DateTime(DateTime.now().year, DateTime.now().month + 1, 31),
              onDaySelected: (selectedDay, focusedDay) {
                _addBillOnDate(selectedDay);
              },
              onDayLongPressed: (selectedDay, focusedDay) {
                _handleLongPressOnDate(selectedDay);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (widget.bill.issueDates.contains(date)) {
                    final count = widget
                        .bill.billsPerDate[date.toString().substring(0, 10)];
                    if (count != null && count > 0) {
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    } else {
                      return null; // Return null if no bills for this date
                    }
                  }
                  return null; // Return null for dates without bills
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _calculateCalendarTotalValue() {
    double total = 0.0;
    for (var date in widget.bill.issueDates) {
      total += widget.bill.dailyValue;
    }
    setState(() {
      _calendarTotalValue = total;
    });
  }

  void _handleLongPressOnDate(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove Bills'),
          content: Text('Are you sure you want to remove bills for this date?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  final dateString = selectedDay.toString().substring(0, 10);
                  final count = widget.bill.billsPerDate[dateString] ?? 0;
                  if (count > 0) {
                    widget.bill.totalValue -= widget.bill.dailyValue * count;
                    widget.bill.issueDates.removeWhere((date) =>
                        date.toString().substring(0, 10) == dateString);
                    widget.bill.billsPerDate.remove(dateString);
                    _calculateCalendarTotalValue();
                    widget
                        .updateTotalValue(); // Update total value in HomeScreen
                    _saveBills(); // Save bills after updating
                  }
                  Navigator.of(context).pop();
                });
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBills() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> billsJson =
        widget.bills.map((bill) => bill.toJson()).toList();
    final String billsString = json.encode(billsJson);
    prefs.setString('bills', billsString);
  }

  _addBillOnDate(DateTime selectedDay) {
    DateTime currentDate = DateTime.now();
    if (selectedDay.isAfter(currentDate)) {
      return Fluttertoast.showToast(
        msg: "You can't add bills for future dates",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    String dateString =
        selectedDay.toString().substring(0, 10); // Format: yyyy-MM-dd

    if (widget.bill.billsPerDate.containsKey(dateString) &&
        widget.bill.billsPerDate[dateString]! > 0) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Warning'),
            content: Text(
                'A bill is already added for this date. Are you sure you want to add another?'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    widget.bill.totalValue += widget.bill.dailyValue;
                    widget.bill.issueDates.add(selectedDay);
                    widget.bill.billsPerDate.update(
                        dateString, (value) => value + 1,
                        ifAbsent: () => 1);
                    _calculateCalendarTotalValue();
                    widget
                        .updateTotalValue(); // Update total value in HomeScreen
                    _saveBills(); // Save bills after updating
                    Navigator.of(context).pop();
                  });
                },
                child: Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('No'),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        widget.bill.totalValue += widget.bill.dailyValue;
        widget.bill.issueDates.add(selectedDay);
        widget.bill.billsPerDate
            .update(dateString, (value) => value + 1, ifAbsent: () => 1);
        widget.updateTotalValue(); // Update total value in HomeScreen
        _calculateCalendarTotalValue();
        _saveBills(); // Save bills after updating
      });
    }
  }
}
