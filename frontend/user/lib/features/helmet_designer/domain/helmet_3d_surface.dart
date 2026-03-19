enum Helmet3dSurface { front, left, right, back }

extension Helmet3dSurfaceX on Helmet3dSurface {
  String get value {
    switch (this) {
      case Helmet3dSurface.front:
        return "front";
      case Helmet3dSurface.left:
        return "left";
      case Helmet3dSurface.right:
        return "right";
      case Helmet3dSurface.back:
        return "back";
    }
  }

  String get label {
    switch (this) {
      case Helmet3dSurface.front:
        return "Mặt trước";
      case Helmet3dSurface.left:
        return "Bên trái";
      case Helmet3dSurface.right:
        return "Bên phải";
      case Helmet3dSurface.back:
        return "Mặt sau";
    }
  }
}

Helmet3dSurface helmet3dSurfaceFromValue(String? value) {
  switch (value?.trim().toLowerCase()) {
    case "left":
      return Helmet3dSurface.left;
    case "right":
      return Helmet3dSurface.right;
    case "back":
      return Helmet3dSurface.back;
    case "front":
    default:
      return Helmet3dSurface.front;
  }
}
