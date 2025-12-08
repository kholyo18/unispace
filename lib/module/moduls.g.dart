// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moduls.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModuleModelAdapter extends TypeAdapter<ModuleModel> {
  @override
  final int typeId = 0;

  @override
  ModuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModuleModel(
      title: fields[0] as String,
      coef: fields[1] as num,
      credits:fields[2] as num,
      tdWeight:40 ,
      tpWeight: 20,
      examWeight: 60,

    )
      .._hasTD = fields[3] as bool
      .._hasTP = fields[4] as bool
      ..wTD = fields[5] as double
      ..wTP = fields[6] as double
      ..wEX = fields[7] as double
      ..td = fields[8] as double?
      ..tp = fields[9] as double?
      ..exam = fields[10] as double?;
  }

  @override
  void write(BinaryWriter writer, ModuleModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.coef)
      ..writeByte(2)
      ..write(obj.credits)
      ..writeByte(3)
      ..write(obj._hasTD)
      ..writeByte(4)
      ..write(obj._hasTP)
      ..writeByte(5)
      ..write(obj.wTD)
      ..writeByte(6)
      ..write(obj.wTP)
      ..writeByte(7)
      ..write(obj.wEX)
      ..writeByte(8)
      ..write(obj.td)
      ..writeByte(9)
      ..write(obj.tp)
      ..writeByte(10)
      ..write(obj.exam);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
