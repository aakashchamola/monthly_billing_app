import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monthly_bills_app/main.dart';
import 'package:table_calendar/table_calendar.dart'; // Adjust this import based on your project structure

void main() {
  testWidgets('Verify AppBar title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the AppBar title is 'Monthly Bills'
    expect(find.text('Monthly Bills'), findsOneWidget);
  });

  testWidgets('Add Bill dialog test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Tap the add button in the AppBar to open the add bill dialog
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that the dialog appears by checking for its title and input fields
    expect(find.text('Add Bill'), findsOneWidget);
    expect(find.byType(TextField),
        findsNWidgets(2)); // Assuming two text fields for name and daily value
  });

  testWidgets('Add and Remove Bill functionality', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Add a bill
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Electricity');
    await tester.enterText(find.byType(TextField).last, '50');
    await tester.tap(find.text('Add'));
    await tester.pump();

    // Verify that the bill appears in the list
    expect(find.text('Electricity'), findsOneWidget);

    // Remove the bill
    await tester.tap(find
        .byIcon(Icons.delete)
        .last); // Assuming the last bill added is being deleted
    await tester.pump();

    // Verify that the bill is removed from the list
    expect(find.text('Electricity'), findsNothing);
  });

  testWidgets('Verify Calendar navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Tap the calendar button for the first bill
    await tester.tap(find.byIcon(Icons.calendar_today).first);
    await tester.pumpAndSettle();

    // Verify that the calendar screen is shown
    expect(find.byType(TableCalendar), findsOneWidget);
  });

  testWidgets('Add Bill on specific date in Calendar',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Add a bill
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Water');
    await tester.enterText(find.byType(TextField).last, '30');
    await tester.tap(find.text('Add'));
    await tester.pump();

    // Navigate to the calendar screen for the added bill
    await tester.tap(find.byIcon(Icons.calendar_today).first);
    await tester.pumpAndSettle();

    // Tap a date in the calendar to add a bill
    await tester
        .tap(find.text('15')); // Assuming the date 15 is in the visible month
    await tester.pumpAndSettle();

    // Verify that the total value is updated
    expect(find.text('Total: Rs. 30.00'), findsOneWidget);
  });

  testWidgets('Remove Bill from specific date in Calendar',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Add a bill
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Internet');
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.tap(find.text('Add'));
    await tester.pump();

    // Navigate to the calendar screen for the added bill
    await tester.tap(find.byIcon(Icons.calendar_today).first);
    await tester.pumpAndSettle();

    // Tap a date in the calendar to add a bill
    await tester
        .tap(find.text('10')); // Assuming the date 10 is in the visible month
    await tester.pumpAndSettle();

    // Long press the date to remove the bill
    await tester.longPress(find.text('10'));
    await tester.pumpAndSettle();

    // Verify that the dialog appears
    expect(find.text('Remove bills for this date?'), findsOneWidget);

    // Confirm removal
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    // Verify that the total value is updated
    expect(find.text('Total: Rs. 0.00'), findsOneWidget);
  });

  // Add more tests as per your app's functionality
}
