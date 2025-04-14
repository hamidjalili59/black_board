// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Point _$PointFromJson(Map<String, dynamic> json) => Point(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
  timestamp: (json['timestamp'] as num).toDouble(),
);

Map<String, dynamic> _$PointToJson(Point instance) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
  'pressure': instance.pressure,
  'timestamp': instance.timestamp,
};

StrokeStyle _$StrokeStyleFromJson(Map<String, dynamic> json) => StrokeStyle(
  color: (json['color'] as num).toInt(),
  width: (json['width'] as num).toDouble(),
  smoothness: (json['smoothness'] as num).toDouble(),
);

Map<String, dynamic> _$StrokeStyleToJson(StrokeStyle instance) =>
    <String, dynamic>{
      'color': instance.color,
      'width': instance.width,
      'smoothness': instance.smoothness,
    };

Stroke _$StrokeFromJson(Map<String, dynamic> json) => Stroke(
  id: json['id'] as String?,
  points:
      (json['points'] as List<dynamic>)
          .map((e) => Point.fromJson(e as Map<String, dynamic>))
          .toList(),
  style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StrokeToJson(Stroke instance) => <String, dynamic>{
  'id': instance.id,
  'points': instance.points,
  'style': instance.style,
};

WhiteBoard _$WhiteBoardFromJson(Map<String, dynamic> json) => WhiteBoard(
  id: json['id'] as String?,
  name: json['name'] as String,
  createdAt: (json['createdAt'] as num?)?.toInt(),
  updatedAt: (json['updatedAt'] as num?)?.toInt(),
  strokes:
      (json['strokes'] as List<dynamic>)
          .map((e) => Stroke.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$WhiteBoardToJson(WhiteBoard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'strokes': instance.strokes,
    };
