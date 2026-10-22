import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_management_dart/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Stock management app loads the dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const StockManagementApp());
    await tester.pumpAndSettle();

    expect(find.text('StockFlow'), findsOneWidget);
    expect(find.text('Your stock, at a glance.'), findsOneWidget);
  });
}
