import 'package:app_template/core/theme/app_typography.dart';
import 'package:app_template/features/paywall/presentation/widgets/upi_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows countdown and Cancel, not Reset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(textTheme: AppTypography.textTheme),
        home: const Scaffold(
          body: UpiQrCode(
            data: 'upi://pay?pa=demo@upi',
            remaining: Duration(minutes: 4, seconds: 12),
          ),
        ),
      ),
    );

    expect(find.text('Reset'), findsNothing);
    expect(find.text('Cancel payment'), findsOneWidget);
    expect(find.text('04:12'), findsOneWidget);
    expect(find.text('Reset for a new code.'), findsNothing);
  });

  testWidgets('expired QR asks the user to cancel and retry', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(textTheme: AppTypography.textTheme),
        home: Scaffold(
          body: UpiQrCode(
            data: 'upi://pay?pa=demo@upi',
            expired: true,
            remaining: Duration.zero,
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.text('This QR code has expired'), findsOneWidget);
    expect(find.text('Cancel and try again for a new code.'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);

    await tester.tap(find.text('Cancel payment'));
    expect(cancelled, isTrue);
  });
}
