import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// ScrollingGrid widget
class ScrollingGrid extends StatelessWidget {
  /// ScrollingGrid constructor
  const ScrollingGrid({
    required this.maxCrossAxisExtent,
    required this.itemCount,
    required this.itemBuilder,
    super.key,
  });

  /// Maximum cross axis extent
  final double maxCrossAxisExtent;

  /// Item count
  final int itemCount;

  /// Item builder
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: _CustomGridDelegate(
        dimension: maxCrossAxisExtent,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: itemBuilder(context, index),
          ),
        );
      },
    );
  }
}

class _CustomGridDelegate extends SliverGridDelegate {
  _CustomGridDelegate({required this.dimension});

  // This is the desired height of each row (and width of each square). When
  // there is not enough room, we shrink this to the width of the scroll view.
  final double dimension;

  // The layout is two rows of squares, then one very wide cell, repeat.

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    // Determine how many squares we can fit per row.
    var count = constraints.crossAxisExtent ~/ dimension;
    if (count < 1) {
      count = 1; // Always fit at least one regardless.
    }
    final squareDimension = constraints.crossAxisExtent / count;
    return _CustomGridLayout(
      crossAxisCount: count,
      childSize: Size(squareDimension, squareDimension),
    );
  }

  @override
  bool shouldRelayout(_CustomGridDelegate oldDelegate) {
    return dimension != oldDelegate.dimension;
  }
}

class _CustomGridLayout extends SliverGridLayout {
  const _CustomGridLayout({
    required this.crossAxisCount,
    required this.childSize,
  }) : assert(crossAxisCount > 0, 'crossAxisCount must be greater than zero');

  final Size childSize;
  final int crossAxisCount;

  @override
  double computeMaxScrollOffset(int childCount) {
    // This returns the scroll offset of the end side of the childCount'th
    // child. Determines how far to allow the user to scroll.
    if (childCount == 0) {
      return 0;
    }
    return (childCount ~/ crossAxisCount) * childSize.height;
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    // This returns the start of the index'th tile.
    //
    // The SliverGridGeometry object returned from this method has four
    // properties. For a grid that scrolls down, as in this example, the four
    // properties are equivalent to x,y,width,height. However, since the
    // GridView is direction agnostic, the names used for SliverGridGeometry are
    // also direction-agnostic.

    final rowIndex = index ~/ crossAxisCount;
    final columnIndex = index % crossAxisCount;
    return SliverGridGeometry(
      scrollOffset: rowIndex * childSize.height, // "y"
      crossAxisOffset: columnIndex * childSize.width, // "x"
      mainAxisExtent: childSize.height, // "height"
      crossAxisExtent: childSize.width, // "width"
    );
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    // This returns the first index that is visible for a given scrollOffset.
    //
    // The GridView only asks for the geometry of children that are visible
    // between the scroll offset passed to getMinChildIndexForScrollOffset and
    // the scroll offset passed to getMaxChildIndexForScrollOffset.
    //
    // It is the responsibility of the SliverGridLayout to ensure that
    // getGeometryForChildIndex is consistent with
    // getMinChildIndexForScrollOffset and getMaxChildIndexForScrollOffset.
    //
    // Not every child between the minimum child index and the maximum child
    // index need be visible (some may have scroll offsets that are outside the
    // view; this happens commonly when the grid view places tiles out of
    // order). However, doing this means the grid view is less efficient, as it
    // will do work for children that are not visible. It is preferred that the
    // children are returned in the order that they are laid out.
    final rows = scrollOffset ~/ childSize.height;
    return rows * crossAxisCount;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    // (See commentary above.)
    final rows = scrollOffset ~/ childSize.height;
    return (rows + 1) * crossAxisCount - 1;
  }
}
