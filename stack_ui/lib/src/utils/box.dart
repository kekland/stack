import 'dart:ui';

enum Corner {
  topLeft([Edge.top, Edge.left]),
  topRight([Edge.top, Edge.right]),
  bottomLeft([Edge.bottom, Edge.left]),
  bottomRight([Edge.bottom, Edge.right])
  ;

  const Corner(this.edges);

  final List<Edge> edges;
  bool get isTop => edges.contains(Edge.top);
  bool get isLeft => edges.contains(Edge.left);
  bool get isBottom => edges.contains(Edge.bottom);
  bool get isRight => edges.contains(Edge.right);

  Corner get opposite => switch (this) {
    .topLeft => .bottomRight,
    .topRight => .bottomLeft,
    .bottomLeft => .topRight,
    .bottomRight => .topLeft,
  };
}

enum Edge {
  top,
  right,
  bottom,
  left
  ;

  bool get isHorizontal => this == Edge.top || this == Edge.bottom;
  bool get isVertical => this == Edge.left || this == Edge.right;

  Edge get opposite => switch (this) {
    .top => .bottom,
    .right => .left,
    .bottom => .top,
    .left => .right,
  };
}

extension RectBoxExtensions on Rect {
  Offset corner(Corner corner) => switch (corner) {
    .topLeft => topLeft,
    .topRight => topRight,
    .bottomLeft => bottomLeft,
    .bottomRight => bottomRight,
  };

  double edge(Edge edge) => switch (edge) {
    .top => top,
    .right => right,
    .bottom => bottom,
    .left => left,
  };

  Rect applyCornerResize(Corner corner, Offset delta, {bool symmetric = false, bool keepAspectRatio = false}) {
    final target = this.corner(corner) + delta;
    final aspectRatio = size.aspectRatio;
    final anchor = symmetric ? center : this.corner(corner.opposite);
    final _delta = target - anchor;

    var newWidth = _delta.dx.abs() * (symmetric ? 2 : 1);
    var newHeight = _delta.dy.abs() * (symmetric ? 2 : 1);

    if (keepAspectRatio) {
      if (newWidth / newHeight < aspectRatio) {
        newWidth = newHeight * aspectRatio;
      } else {
        newHeight = newWidth / aspectRatio;
      }
    }

    if (symmetric) return Rect.fromCenter(center: anchor, width: newWidth, height: newHeight);
    final sx = _delta.dx.sign;
    final sy = _delta.dy.sign;

    return Rect.fromPoints(
      anchor,
      anchor + Offset(newWidth * sx, newHeight * sy),
    );
  }

  Rect applyEdgeResize(Edge edge, Offset delta, {bool symmetric = false, bool keepAspectRatio = false}) {
    final target = Offset(this.edge(edge), this.edge(edge)) + delta;
    final aspectRatio = size.aspectRatio;
    final anchor = symmetric ? center : Offset(this.edge(edge.opposite), this.edge(edge.opposite));
    var _delta = target - anchor;

    if (symmetric) _delta *= 2.0;

    var newWidth = width;
    var newHeight = height;

    if (edge.isVertical) {
      newWidth = _delta.dx.abs();
      if (keepAspectRatio) newHeight = newWidth / aspectRatio;
    } else {
      newHeight = _delta.dy.abs();
      if (keepAspectRatio) newWidth = newHeight * aspectRatio;
    }

    final sx = _delta.dx.sign;
    final sy = _delta.dy.sign;

    late final Offset newCenter;
    if (symmetric) {
      newCenter = center;
    } else {
      newCenter = switch (edge) {
        .left || .right => Offset(anchor.dx + (newWidth / 2.0 * sx), center.dy),
        .top || .bottom => Offset(center.dx, anchor.dy + (newHeight / 2.0 * sy)),
      };
    }

    return Rect.fromCenter(center: newCenter, width: newWidth, height: newHeight);
  }
}
