class IndicesModel {
  final int todayIndex;
  final List<int> weekIndices;
  final List<int> monthIndices;

  const IndicesModel({
    required this.todayIndex,
    required this.weekIndices,
    required this.monthIndices,
  });

  factory IndicesModel.fromJson(Map<String, dynamic> json) {
    return IndicesModel(
      todayIndex: json['todayIndex'],
      weekIndices: List<int>.from(json['weekIndices']),
      monthIndices: List<int>.from(json['monthIndices']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayIndex': todayIndex,
      'weekIndices': weekIndices,
      'monthIndices': monthIndices,
    };
  }

  @override
  String toString() {
    return 'IndicesModel{todayIndex: $todayIndex, weekIndices: $weekIndices, monthIndices: $monthIndices}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndicesModel &&
          runtimeType == other.runtimeType &&
          todayIndex == other.todayIndex &&
          weekIndices == other.weekIndices &&
          monthIndices == other.monthIndices;

  @override
  int get hashCode =>
      todayIndex.hashCode ^ weekIndices.hashCode ^ monthIndices.hashCode;
}
