class C {
  final double x;
  final double y;
  final double z;

  const C({required this.x, required this.y, required this.z});

  factory C.fromJson(Map<String, dynamic> json) {
    return C(x: json['x'], y: json['y'], z: json['z']);
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }

  @override
  String toString() {
    return 'C{x: $x, y: $y, z: $z}';
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

class ListOfC {
  final List<C> list;

  const ListOfC({required this.list});

  factory ListOfC.fromJson(List<dynamic> json) {
    return ListOfC(
      list: json.map((e) => C.fromJson(e)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return list.map((e) => e.toJson()).toList();
  }

  @override
  String toString() {
    return 'ListOfC{list: $list}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListOfC &&
          runtimeType == other.runtimeType &&
          list == other.list;

  @override
  int get hashCode => list.hashCode;
}

class ListOfListOfC {
  final List<List<C>> list;

  const ListOfListOfC({required this.list});

  factory ListOfListOfC.fromJson(List<dynamic> json) {
    return ListOfListOfC(
      list: json.map((e) => ListOfC.fromJson(e).list).toList(),
    );
  }

  List<List<Map<String, dynamic>>> toJson() {
    return list.map((e) => ListOfC(list: e).toJson()).toList();
  }

  @override
  String toString() {
    return 'ListOfListOfC{list: $list}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListOfListOfC &&
          runtimeType == other.runtimeType &&
          list == other.list;

  @override
  int get hashCode => list.hashCode;
}
