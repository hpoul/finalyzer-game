import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// based on https://github.com/flutter/flutter/issues/20608#issuecomment-451040159
class IndexOffsetListView extends StatelessWidget {
  const IndexOffsetListView.builder({
    @required this.initialIndex,
    @required this.itemCount,
    @required this.itemBuilder,
  });

  final int initialIndex;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final Key forwardListKey = UniqueKey();
    final Widget forwardList = SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return itemBuilder(context, index + initialIndex);
        },
        childCount: itemCount - initialIndex,
      ),
      key: forwardListKey,
    );

    final Widget reverseList = SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return itemBuilder(context, -1 - index + initialIndex);
        },
        childCount: initialIndex,
      ),
    );
    return Scrollable(viewportBuilder: (BuildContext context, ViewportOffset offset) {
      return Viewport(offset: offset, center: forwardListKey, slivers: [
        reverseList,
        forwardList,
      ]);
    });
  }
}
