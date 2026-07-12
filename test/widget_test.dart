import 'package:flutter_query/flutter_query.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App builds with QueryClient', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(queryClient: QueryClient()));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
