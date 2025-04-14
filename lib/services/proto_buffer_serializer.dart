import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/white_board.dart';
import '../models/stroke.dart';
import '../models/stroke_style.dart';
import '../models/point.dart';

/// کلاس مسئول سریالایز و دسریالایز کردن داده‌ها با پروتوباف
class ProtobufSerializer {
  /// تبدیل نقطه به پروتوباف
  static Uint8List serializePoint(Point point) {
    // ساختار پروتوباف: tag = field_number << 3 | wire_type
    // x: field_number = 1, wire_type = 1 (64-bit)
    // y: field_number = 2, wire_type = 1 (64-bit)
    // pressure: field_number = 3, wire_type = 1 (64-bit)
    // timestamp: field_number = 4, wire_type = 0 (varint)

    final builder = BytesBuilder();

    // x (field 1) - double
    builder.addByte(0x09); // tag: 1 << 3 | 1
    builder.add(_encodeDouble(point.x));

    // y (field 2) - double
    builder.addByte(0x11); // tag: 2 << 3 | 1
    builder.add(_encodeDouble(point.y));

    // pressure (field 3) - double
    builder.addByte(0x19); // tag: 3 << 3 | 1
    builder.add(_encodeDouble(point.pressure));

    return builder.toBytes();
  }

  /// تبدیل پروتوباف به نقطه
  static Point deserializePoint(Uint8List data) {
    double x = 0, y = 0, pressure = 0;
    int pos = 0;

    while (pos < data.length) {
      final tag = data[pos++];
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      if (wireType == 1) {
        // Fixed64
        switch (fieldNumber) {
          case 1: // x
            x = _decodeDouble(data.sublist(pos, pos + 8));
            pos += 8;
            break;
          case 2: // y
            y = _decodeDouble(data.sublist(pos, pos + 8));
            pos += 8;
            break;
          case 3: // pressure
            pressure = _decodeDouble(data.sublist(pos, pos + 8));
            pos += 8;
            break;
        }
      } else if (wireType == 0) {
        // Varint
        // پرش از داده‌های varint
        while (data[pos] & 0x80 != 0) {
          pos++;
        }
        pos++;
      } else {
        // پرش از فیلد ناشناخته
        final length = data[pos++];
        pos += length;
      }
    }

    return Point(x: x, y: y, pressure: pressure);
  }

  /// تبدیل استایل خط به پروتوباف
  static Uint8List serializeStrokeStyle(StrokeStyle style) {
    final builder = BytesBuilder();

    // color (field 1) - string
    final colorHex = style.color.value.toRadixString(16).padLeft(8, '0');
    final colorBytes = utf8.encode(colorHex);
    builder.addByte(0x0A); // tag: 1 << 3 | 2 (length-delimited)
    builder.addByte(colorBytes.length); // length
    builder.add(colorBytes); // string

    // thickness (field 2) - double
    builder.addByte(0x11); // tag: 2 << 3 | 1
    builder.add(_encodeDouble(style.thickness));

    // isEraser (field 3) - bool
    builder.addByte(0x18); // tag: 3 << 3 | 0 (varint)
    builder.addByte(style.type == StrokeType.dotted ? 1 : 0);

    return builder.toBytes();
  }

  /// تبدیل پروتوباف به استایل خط
  static StrokeStyle deserializeStrokeStyle(Uint8List data) {
    String color = "FF000000";
    double thickness = 2.0;
    bool isEraser = false;
    int pos = 0;

    while (pos < data.length) {
      final tag = data[pos++];
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (wireType) {
        case 0: // varint
          if (fieldNumber == 3) {
            // isEraser
            isEraser = data[pos++] != 0;
          } else {
            // پرش از varint ناشناخته
            while (pos < data.length && (data[pos] & 0x80) != 0) pos++;
            pos++;
          }
          break;
        case 1: // fixed64
          if (fieldNumber == 2) {
            // thickness
            thickness = _decodeDouble(data.sublist(pos, pos + 8));
          }
          pos += 8;
          break;
        case 2: // length-delimited
          final length = data[pos++];
          if (fieldNumber == 1) {
            // color
            color = utf8.decode(data.sublist(pos, pos + length));
          }
          pos += length;
          break;
      }
    }

    return StrokeStyle(
      color: Color(int.parse(color, radix: 16)),
      thickness: thickness,
      type: isEraser ? StrokeType.dotted : StrokeType.solid,
    );
  }

  /// تبدیل استروک به پروتوباف
  static Uint8List serializeStroke(Stroke stroke) {
    final builder = BytesBuilder();

    // id (field 1) - string
    final idBytes = utf8.encode(stroke.id);
    builder.addByte(0x0A); // tag: 1 << 3 | 2
    builder.addByte(idBytes.length);
    builder.add(idBytes);

    // points (field 2) - repeated Point
    for (final point in stroke.points) {
      final pointData = serializePoint(point);
      builder.addByte(0x12); // tag: 2 << 3 | 2
      builder.addByte(pointData.length);
      builder.add(pointData);
    }

    // style (field 3) - StrokeStyle
    final styleData = serializeStrokeStyle(stroke.style);
    builder.addByte(0x1A); // tag: 3 << 3 | 2
    builder.addByte(styleData.length);
    builder.add(styleData);

    return builder.toBytes();
  }

  /// تبدیل پروتوباف به استروک
  static Stroke deserializeStroke(Uint8List data) {
    String id = "";
    final points = <Point>[];
    StrokeStyle? style;
    int pos = 0;

    while (pos < data.length) {
      final tag = data[pos++];
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      if (wireType == 2) {
        // length-delimited
        final length = data[pos++];
        final fieldData = data.sublist(pos, pos + length);

        switch (fieldNumber) {
          case 1: // id
            id = utf8.decode(fieldData);
            break;
          case 2: // point
            points.add(deserializePoint(fieldData));
            break;
          case 3: // style
            style = deserializeStrokeStyle(fieldData);
            break;
        }

        pos += length;
      } else {
        // پرش از فیلد ناشناخته
        pos += (wireType == 0) ? 1 : (wireType == 1 ? 8 : data[pos++]);
      }
    }

    return Stroke(
      id: id,
      points: points,
      startTime: DateTime.now().millisecondsSinceEpoch,
      style:
          style ??
          StrokeStyle(
            color: Colors.black,
            thickness: 2.0,
            type: StrokeType.solid,
          ),
    );
  }

  /// تبدیل وایت‌بورد به پروتوباف
  static Uint8List serializeWhiteBoard(WhiteBoard whiteBoard) {
    final builder = BytesBuilder();

    // id (field 1) - string
    final idBytes = utf8.encode(whiteBoard.id);
    builder.addByte(0x0A); // tag: 1 << 3 | 2
    builder.addByte(idBytes.length);
    builder.add(idBytes);

    // name (field 2) - string
    final nameBytes = utf8.encode(whiteBoard.name);
    builder.addByte(0x12); // tag: 2 << 3 | 2
    builder.addByte(nameBytes.length);
    builder.add(nameBytes);

    // createdAt (field 3) - int64
    builder.addByte(0x18); // tag: 3 << 3 | 0
    builder.add(_encodeVarint(whiteBoard.createdAt.millisecondsSinceEpoch));

    // updatedAt (field 4) - int64
    builder.addByte(0x20); // tag: 4 << 3 | 0
    builder.add(_encodeVarint(whiteBoard.updatedAt.millisecondsSinceEpoch));

    // strokes (field 5) - repeated Stroke
    for (final stroke in whiteBoard.strokes) {
      final strokeData = serializeStroke(stroke);
      builder.addByte(0x2A); // tag: 5 << 3 | 2
      builder.add(_encodeVarint(strokeData.length));
      builder.add(strokeData);
    }

    return builder.toBytes();
  }

  /// تبدیل پروتوباف به وایت‌بورد
  static WhiteBoard deserializeWhiteBoard(Uint8List data) {
    String id = "";
    String name = "";
    int createdAt = 0;
    int updatedAt = 0;
    final strokes = <Stroke>[];
    int pos = 0;

    while (pos < data.length) {
      final tag = data[pos++];
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;

      switch (wireType) {
        case 0: // varint
          final value = _decodeVarint(data, pos);
          pos += value.bytesRead;

          if (fieldNumber == 3) {
            createdAt = value.result;
          } else if (fieldNumber == 4) {
            updatedAt = value.result;
          }
          break;
        case 2: // length-delimited
          final lengthData = _decodeVarint(data, pos);
          pos += lengthData.bytesRead;
          final length = lengthData.result;

          if (fieldNumber == 1) {
            id = utf8.decode(data.sublist(pos, pos + length));
          } else if (fieldNumber == 2) {
            name = utf8.decode(data.sublist(pos, pos + length));
          } else if (fieldNumber == 5) {
            final strokeData = data.sublist(pos, pos + length);
            strokes.add(deserializeStroke(strokeData));
          }

          pos += length;
          break;
        default:
          // پرش از فیلد ناشناخته
          if (wireType == 1) {
            // fixed64
            pos += 8;
          } else {
            // نباید اینجا بیاید
            pos++;
          }
      }
    }

    return WhiteBoard(
      id: id,
      name: name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      strokes: strokes,
    );
  }

  // Helper methods

  /// تبدیل عدد double به بایت‌های پروتوباف
  static Uint8List _encodeDouble(double value) {
    final data = ByteData(8);
    data.setFloat64(0, value, Endian.little);
    return Uint8List.view(data.buffer);
  }

  /// تبدیل بایت‌های پروتوباف به عدد double
  static double _decodeDouble(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    return data.getFloat64(0, Endian.little);
  }

  /// تبدیل عدد صحیح به varint پروتوباف
  static Uint8List _encodeVarint(int value) {
    final bytes = <int>[];

    while (value >= 0x80) {
      bytes.add((value & 0x7F) | 0x80);
      value >>= 7;
    }

    bytes.add(value & 0x7F);
    return Uint8List.fromList(bytes);
  }

  /// تبدیل varint پروتوباف به عدد صحیح
  static ({int result, int bytesRead}) _decodeVarint(
    Uint8List bytes,
    int offset,
  ) {
    int result = 0;
    int shift = 0;
    int bytesRead = 0;

    while (true) {
      if (offset >= bytes.length) {
        break;
      }

      final byte = bytes[offset++];
      bytesRead++;

      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        break;
      }

      shift += 7;
    }

    return (result: result, bytesRead: bytesRead);
  }
}
