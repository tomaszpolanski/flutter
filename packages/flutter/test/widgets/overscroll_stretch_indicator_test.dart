// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTest(
    Key box1Key,
    Key box2Key,
    Key box3Key,
    ScrollController controller, {
    Axis axis = Axis.vertical,
    bool reverse = false,
  }) {
    final AxisDirection axisDirection;
    switch (axis) {
      case Axis.horizontal:
        axisDirection = reverse ? AxisDirection.left : AxisDirection.right;
        break;
      case Axis.vertical:
        axisDirection = reverse ? AxisDirection.up : AxisDirection.down;
        break;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: StretchingOverscrollIndicator(
          axisDirection: axisDirection,
          child: CustomScrollView(
            reverse: reverse,
            scrollDirection: axis,
            controller: controller,
            slivers: <Widget>[
              SliverToBoxAdapter(child: Container(
                color: const Color(0xD0FF0000),
                key: box1Key,
                height: 250.0,
                width: 300.0,
              )),
              SliverToBoxAdapter(child: Container(
                color: const Color(0xFFFFFF00),
                key: box2Key,
                height: 250.0,
                width: 300.0,
              )),
              SliverToBoxAdapter(child: Container(
                color: const Color(0xFF6200EA),
                key: box3Key,
                height: 250.0,
                width: 300.0,
              )),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Stretch overscroll vertically', (WidgetTester tester) async {
    final Key box1Key = UniqueKey();
    final Key box2Key = UniqueKey();
    final Key box3Key = UniqueKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      buildTest(box1Key, box2Key, box3Key, controller),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.start.png'),
    );

    TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the start
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero).dy, greaterThan(255.0));
    expect(box3.localToGlobal(Offset.zero).dy, greaterThan(510.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.start.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back to the start
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));

    // Jump to end of the list
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(controller.offset, 150.0);
    expect(box1.localToGlobal(Offset.zero).dy, -150.0);
    expect(box2.localToGlobal(Offset.zero).dy, 100.0);
    expect(box3.localToGlobal(Offset.zero).dy, 350.0);
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.end.png'),
    );

    gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the end
    await gesture.moveBy(const Offset(0.0, -200.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dy, lessThan(-165));
    expect(box2.localToGlobal(Offset.zero).dy, lessThan(90.0));
    expect(box3.localToGlobal(Offset.zero).dy, lessThan(350.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.end.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back
    expect(box1.localToGlobal(Offset.zero).dy, -150.0);
    expect(box2.localToGlobal(Offset.zero).dy, 100.0);
    expect(box3.localToGlobal(Offset.zero).dy, 350.0);
  });

  testWidgets('Stretch overscroll works in reverse - vertical', (WidgetTester tester) async {
    final Key box1Key = UniqueKey();
    final Key box2Key = UniqueKey();
    final Key box3Key = UniqueKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      buildTest(box1Key, box2Key, box3Key, controller, reverse: true),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), const Offset(0.0, 350.0));
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 100.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, -150.0));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll
    await gesture.moveBy(const Offset(0.0, -200.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dy, lessThan(350.0));
    expect(box2.localToGlobal(Offset.zero).dy, lessThan(100.0));
    expect(box3.localToGlobal(Offset.zero).dy, lessThan(-150.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.vertical.reverse.png'),
    );
  });

  testWidgets('Stretch overscroll works in reverse - horizontal', (WidgetTester tester) async {
    final Key box1Key = UniqueKey();
    final Key box2Key = UniqueKey();
    final Key box3Key = UniqueKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
        buildTest(
          box1Key,
          box2Key,
          box3Key,
          controller,
          axis: Axis.horizontal,
          reverse: true,
        ),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), const Offset(500.0, 0.0));
    expect(box2.localToGlobal(Offset.zero), const Offset(200.0, 0.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(-100.0, 0.0));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll
    await gesture.moveBy(const Offset(200.0, 0.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dx, greaterThan(500.0));
    expect(box2.localToGlobal(Offset.zero).dx, greaterThan(200.0));
    expect(box3.localToGlobal(Offset.zero).dx, greaterThan(-100.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.reverse.png'),
    );
  });

  testWidgets('Stretch overscroll horizontally', (WidgetTester tester) async {
    final Key box1Key = UniqueKey();
    final Key box2Key = UniqueKey();
    final Key box3Key = UniqueKey();
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      buildTest(box1Key, box2Key, box3Key, controller, axis: Axis.horizontal)
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(300.0, 0.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(600.0, 0.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.start.png'),
    );

    TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the start
    await gesture.moveBy(const Offset(200.0, 0.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero).dx, greaterThan(305.0));
    expect(box3.localToGlobal(Offset.zero).dx, greaterThan(610.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.start.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back to the start
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(300.0, 0.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(600.0, 0.0));

    // Jump to end of the list
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(controller.offset, 100.0);
    expect(box1.localToGlobal(Offset.zero).dx, -100.0);
    expect(box2.localToGlobal(Offset.zero).dx, 200.0);
    expect(box3.localToGlobal(Offset.zero).dx, 500.0);
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.end.png'),
    );

    gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the end
    await gesture.moveBy(const Offset(-200.0, 0.0));
    await tester.pumpAndSettle();
    expect(box1.localToGlobal(Offset.zero).dx, lessThan(-116.0));
    expect(box2.localToGlobal(Offset.zero).dx, lessThan(190.0));
    expect(box3.localToGlobal(Offset.zero).dx, lessThan(500.0));
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('overscroll_stretch.horizontal.end.stretched.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Stretch released back
    expect(box1.localToGlobal(Offset.zero).dx, -100.0);
    expect(box2.localToGlobal(Offset.zero).dx, 200.0);
    expect(box3.localToGlobal(Offset.zero).dx, 500.0);
  });

  testWidgets('Disallow stretching overscroll', (WidgetTester tester) async {
    final Key box1Key = UniqueKey();
    final Key box2Key = UniqueKey();
    final Key box3Key = UniqueKey();
    final ScrollController controller = ScrollController();
    double indicatorNotification =0;
    await tester.pumpWidget(
      NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification notification) {
          notification.disallowIndicator();
          indicatorNotification += 1;
          return false;
        },
        child: buildTest(box1Key, box2Key, box3Key, controller),
      )
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    final RenderBox box1 = tester.renderObject(find.byKey(box1Key));
    final RenderBox box2 = tester.renderObject(find.byKey(box2Key));
    final RenderBox box3 = tester.renderObject(find.byKey(box3Key));

    expect(indicatorNotification, 0.0);
    expect(controller.offset, 0.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(CustomScrollView)));
    // Overscroll the start, should not stretch
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(indicatorNotification, 1.0);
    expect(box1.localToGlobal(Offset.zero), Offset.zero);
    expect(box2.localToGlobal(Offset.zero), const Offset(0.0, 250.0));
    expect(box3.localToGlobal(Offset.zero), const Offset(0.0, 500.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Stretch does not overflow bounds of container', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/90197
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: Column(
          children: <Widget>[
            StretchingOverscrollIndicator(
              axisDirection: AxisDirection.down,
              child: SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: 20,
                  itemBuilder: (BuildContext context, int index){
                    return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text('Index $index'),
                    );
                  },
                ),
              ),
            ),
            Opacity(
              opacity: 0.5,
              child: Container(
                color: const Color(0xD0FF0000),
                height: 100,
              ),
            )
          ],
        )
      )
    ));

    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, 51.0);

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('Index 1')));
    // Overscroll the start.
    await gesture.moveBy(const Offset(0.0, 200.0));
    await tester.pumpAndSettle();
    expect(find.text('Index 1'), findsOneWidget);
    expect(tester.getCenter(find.text('Index 1')).dy, greaterThan(0));
    // Image should not show the text overlapping the red area below the list.
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('overscroll_stretch.no_overflow.png'),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
