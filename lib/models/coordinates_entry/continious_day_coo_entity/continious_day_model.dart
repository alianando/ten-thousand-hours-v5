import '../coordinate_model.dart';

class ContiniousDayModel {
  final List<C> todayCoordinates;
  final List<List<C>> otherDayCoordinates;

  const ContiniousDayModel({
    required this.todayCoordinates,
    required this.otherDayCoordinates,
  });
}
