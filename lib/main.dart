import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monthly_bills_app/bill_history.dart';
import 'package:monthly_bills_app/calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monthly Bills App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class Bill {
  final String name;
  final double dailyValue;
  double totalValue;
  List<DateTime> issueDates;
  List<Map<String, dynamic>> previousCycles;
  Map<String, int> billsPerDate = {};

  Bill({
    required this.name,
    required this.dailyValue,
    required this.totalValue,
    required this.issueDates,
    required this.previousCycles,
    required this.billsPerDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dailyValue': dailyValue,
      'totalValue': totalValue,
      'issueDates': issueDates.map((date) => date.toIso8601String()).toList(),
      'previousCycles': previousCycles,
      'billsPerDate': billsPerDate,
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      name: json['name'],
      dailyValue: json['dailyValue'],
      totalValue: json['totalValue'],
      issueDates: (json['issueDates'] as List<dynamic>)
          .map((date) => DateTime.parse(date as String))
          .toList(),
      previousCycles: (json['previousCycles'] as List<dynamic>)
          .map((cycle) => Map<String, dynamic>.from(cycle))
          .toList(),
      billsPerDate: (json['billsPerDate'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }

  void resetBill() {
    if (issueDates.isNotEmpty) {
      final billMonth = issueDates.first.month;
      final billYear = issueDates.first.year;

      final cycleData = {
        'total': totalValue,
        'month': '$billYear-${billMonth.toString().padLeft(2, '0')}',
        'dates':
            issueDates.fold<Map<String, Map<String, dynamic>>>({}, (map, date) {
          final dateString = date.toString().substring(0, 10);
          if (!map.containsKey(dateString)) {
            map[dateString] = {'count': 1, 'value': dailyValue};
          } else {
            map[dateString]?['count']++;
            map[dateString]?['value'] += dailyValue;
          }
          return map;
        }),
      };
      previousCycles.add(cycleData);
    }
    totalValue = 0.0;
    issueDates.clear();
    billsPerDate.clear(); // Clear bills per date when resetting bill
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Bill> bills = [];
  double _totalValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  double _calculateTodayValue() {
    double todayValue = 0.0;
    DateTime today = DateTime.now();
    for (var bill in bills) {
      if (bill.issueDates.any((date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day)) {
        todayValue += bill.dailyValue;
      }
    }
    return todayValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Bills'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createBill,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          double todayValue = _calculateBillTodayValue(
              bill); // Calculate today's value for this specific bill
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Text(
                          'Total: Rs. ${bill.totalValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ],
                    ),
                    // Text(
                    //   "{Today's Value: Rs. ${todayValue.toStringAsFixed(2)}}",
                    //   style: const TextStyle(
                    //       fontWeight: FontWeight.bold, fontSize: 20),
                    // ) // should show the bill of the current date,
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // IconButton(
                    //   icon: Icon(Icons.remove),
                    //   onPressed: () => _updateBill(bill, false),
                    // ),
                    // IconButton(
                    //   icon: Icon(Icons.add),
                    //   onPressed: () => _addBill(bill),
                    // ),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _navigateToCalendar(bill),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () => _resetBills(bill),
                    ),
                    IconButton(
                      icon: Icon(Icons.history),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BillHistoryScreen(bill: bill),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _confirmDeleteBill(context, bill),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteBill(BuildContext context, Bill bill) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text(
              'Are you sure you want to delete ${bill.name} and all its history?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteBillAndHistory(bill);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteBillAndHistory(Bill bill) {
    setState(() {
      bills.remove(bill);
      _saveBills();
    });
  }

  Future<void> _saveBills() async {
    final prefs = await SharedPreferences.getInstance();
    final billsString =
        json.encode(bills.map((bill) => bill.toJson()).toList());
    prefs.setString('bills', billsString);
  }

  Future<void> _loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final billsString = prefs.getString('bills');
    if (billsString != null) {
      final List<dynamic> billsJson = json.decode(billsString);
      setState(() {
        bills = billsJson.map((json) => Bill.fromJson(json)).toList();
        _updateTotalValue();
      });
    }
  }

  // void _updateBill(Bill bill, bool isIncrement) {
  //   setState(() {
  //     DateTime today = DateTime.now();
  //     if (isIncrement) {
  //       bill.totalValue += bill.dailyValue;
  //       bill.issueDates.add(today);
  //       // Update billsPerDate for today
  //       if (bill.billsPerDate.containsKey(today.toString())) {
  //         bill.billsPerDate[today.toString()] =
  //             bill.billsPerDate[today.toString()]! + 1;
  //       } else {
  //         bill.billsPerDate[today.toString()] = 1;
  //       }
  //     } else if (bill.totalValue > 0) {
  //       // todayValue > 0 ? todayValue = 0 : null;
  //       bill.totalValue -= bill.dailyValue;
  //       // Remove today's value only
  //       bill.issueDates.removeWhere((date) =>
  //           date.year == today.year &&
  //           date.month == today.month &&
  //           date.day == today.day);
  //       // Update billsPerDate for today
  //       if (bill.billsPerDate.containsKey(today.toString())) {
  //         if (bill.billsPerDate[today.toString()]! > 1) {
  //           bill.billsPerDate[today.toString()] =
  //               bill.billsPerDate[today.toString()]! - 1;
  //         } else {
  //           bill.billsPerDate.remove(today.toString());
  //         }
  //       }
  //     }
  //     _saveBills();
  //     // _updateTotalValue();
  //     _calculateTodayValue(); // Update today's value after adding or removing
  //   });
  // }

  void _createBill() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        double dailyValue = 0.0;
        return AlertDialog(
          title: Text('Add Bill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Bill Name'),
                onChanged: (value) {
                  name = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Daily Value'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  dailyValue = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  bills.add(Bill(
                    name: name,
                    dailyValue: dailyValue,
                    totalValue: 0.0,
                    issueDates: [],
                    previousCycles: [],
                    billsPerDate: {},
                  ));
                  _saveBills();
                });
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _resetBills(Bill bill) {
    setState(() {
      bill.resetBill();
      _updateTotalValue(); // Update the total value after resetting the bill
      _saveBills();
    });
  }

  void _updateTotalValue() {
    double total = 0.0;
    for (var bill in bills) {
      bill.totalValue = 0.0; // Reset total value before recalculating
      for (var date in bill.issueDates) {
        bill.totalValue += bill.dailyValue;
      }
      total += bill.totalValue;
    }
    setState(() {
      // Update the total value displayed on HomeScreen
      _totalValue = total;
    });
  }

  void _addBill(Bill bill) {
    // Check if todayValue already has a value for today's bill
    DateTime today = DateTime.now();
    bool alreadyAdded = bill.issueDates.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
    if (alreadyAdded) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Confirm Add'),
            content: Text(
                'A bill has already been added for today. Are you sure you want to add another one?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  setState(() {
                    bill.totalValue += bill.dailyValue;
                    bill.issueDates.add(today);
                    // Update billsPerDate for today
                    if (bill.billsPerDate.containsKey(today.toString())) {
                      bill.billsPerDate[today.toString()] =
                          bill.billsPerDate[today.toString()]! + 1;
                    } else {
                      bill.billsPerDate[today.toString()] = 1;
                    }
                    _saveBills();
                    _calculateTodayValue(); // Update today's value
                    _updateTotalValue();
                  });
                },
                child: Text('Add'),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        _updateBill(bill, true);
        _calculateTodayValue(); // Update today's value
      });
    }
  }

  void _updateBill(Bill bill, bool increment) {
    setState(() {
      final today = DateTime.now();
      if (increment) {
        bill.issueDates.add(today);
        bill.totalValue += bill.dailyValue;
      } else {
        bill.issueDates.removeWhere((date) =>
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day);
        bill.totalValue -= bill.dailyValue;
        bill.billsPerDate.remove(today.toString());
        if (bill.billsPerDate.containsKey(today.toString())) {
          // bill.billsPerDate[today.toString()] =
          //     bill.billsPerDate[today.toString()]! - 1;
          // if (bill.billsPerDate[today.toString()]! <= 0) {
          //   bill.billsPerDate.remove(today.toString());
          // }
          bill.billsPerDate.remove(today.toString());
        }
      }
      _updateTotalValue();
      _saveBills();
    });
    // BillCalendarScreen.updateCalendar(bill);
  }

  double _calculateBillTodayValue(Bill bill) {
    final today = DateTime.now();
    double todayValue = 0.0;
    for (var date in bill.issueDates) {
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        todayValue += bill.dailyValue;
      }
    }
    return todayValue;
  }

  void _navigateToCalendar(Bill bill) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillCalendarScreen(
          bill: bill,
          bills: bills,
          updateTotalValue: _updateTotalValue,
        ),
      ),
    );
  }
}
