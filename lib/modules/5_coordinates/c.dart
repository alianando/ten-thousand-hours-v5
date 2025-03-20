class C {
  final double x;
  final double y;
  final double z;

  const C(this.x, this.y, this.z);

  factory C.fromJson(Map<String, dynamic> json) {
    return C(json['x'], json['y'], json['z']);
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }

  @override
  String toString() {
    return '{$x, y: $y, z: $z}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is C &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}
