import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_kit/shared/widgets/pagination/pagination_wrapper.dart';

void main() {
  testWidgets('PaginationWrapper loads data on startup and scrolls to load more', (WidgetTester tester) async {
    // Set screen size to fit 2.5 items (making list scrollable)
    tester.view.physicalSize = const Size(800, 500);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = PaginationController<String>();
    final List<Map<String, int>> fetchLog = [];

    Future<List<String>> mockFetch(int page, int pageSize) async {
      fetchLog.add({'page': page, 'pageSize': pageSize});
      return List.generate(pageSize, (i) => 'Page $page - Item $i');
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginationWrapper<String>.builder(
            controller: controller,
            fetchData: mockFetch,
            pageSize: 5,
            itemBuilder: (context, item) => SizedBox(
              height: 200, // Large height to easily enable scrolling
              child: Text(item),
            ),
          ),
        ),
      ),
    );

    // 1. Initial State: should load initial data
    await tester.pump(); // trigger frame

    // Expect the first page fetch log
    expect(fetchLog.length, 1);
    expect(fetchLog[0]['page'], 1);

    // Re-render and wait for items to paint
    await tester.pump();
    expect(find.text('Page 1 - Item 0'), findsOneWidget);
    expect(find.text('Page 1 - Item 2'), findsOneWidget); // Item 2 is visible within 500px height

    // 2. Scroll down to trigger load more
    final listFinder = find.byType(ListView);
    expect(listFinder, findsOneWidget);

    // Scroll drag down past bottom trigger
    await tester.drag(listFinder, const Offset(0, -400));
    await tester.pump(); // pump to handle listener trigger
    await tester.pumpAndSettle(); // let async loading settle

    // Verify page 2 was fetched
    expect(fetchLog.length, 2);
    expect(fetchLog[1]['page'], 2);

    // Scroll down further to bring Page 2 - Item 0 into view
    await tester.drag(listFinder, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Page 2 - Item 0'), findsOneWidget);

    // 3. Test filter via controller
    controller.updateFilteredList((items) => items.where((e) => e.contains('Item 0')).toList());
    await tester.pumpAndSettle();

    // Only items containing 'Item 0' should be rendered
    expect(find.text('Page 1 - Item 0'), findsOneWidget);
    expect(find.text('Page 2 - Item 0'), findsOneWidget);
    expect(find.text('Page 1 - Item 2'), findsNothing);

    // Clear filter
    controller.clearFilter();
    await tester.pumpAndSettle();
    expect(find.text('Page 1 - Item 2'), findsOneWidget);
  });
}
