import 'package:hive/hive.dart';

 part 'moduls.g.dart';

@HiveType(typeId: 0)
class ModuleModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double coef;

  @HiveField(2)
  double credits;

  @HiveField(3)
  bool _hasTD;

  @HiveField(4)
  bool _hasTP;

  @HiveField(5)
  double wTD;

  @HiveField(6)
  double wTP;

  @HiveField(7)
  double wEX;

  @HiveField(8)
  double? td;

  @HiveField(9)
  double? tp;

  @HiveField(10)
  double? exam;

  ModuleModel({
    required this.title,
    required num coef,
    required num credits,
    double tdWeight = 0,
    double tpWeight = 0,
    double examWeight = 0,
  })  : coef = coef.toDouble(),
        credits = credits.toDouble(),
        _hasTD = tdWeight > 0,
        _hasTP = tpWeight > 0,
        wTD = tdWeight / 100,
        wTP = tpWeight / 100,
        wEX = examWeight / 100,
        td = 0,
        tp = 0,
        exam = 0;

  bool get hasTD => _hasTD;

  bool get hasTP => _hasTP;

  double get moy {
    final totalW = wTD + wTP + wEX;

    if (totalW <= 0) return 0;

    double normalize(double weight) {
      return weight / totalW;
    }

    final value =
        (td ?? 0) * normalize(wTD) +
            (tp ?? 0) * normalize(wTP) +
            (exam ?? 0) * normalize(wEX);

    return double.parse(value.toStringAsFixed(2));
  }
}