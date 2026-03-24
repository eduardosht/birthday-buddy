import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class Group {
  final String id;
  final String name;
  final int colorValue;
  final String emoji;
  final DateTime createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.emoji,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  factory Group.create({
    required String name,
    required int colorValue,
    String emoji = '🎉',
  }) {
    return Group(
      id: const Uuid().v4(),
      name: name,
      colorValue: colorValue,
      emoji: emoji,
      createdAt: DateTime.now(),
    );
  }

  Group copyWith({
    String? name,
    int? colorValue,
    String? emoji,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['colorValue'] as int,
      emoji: map['emoji'] as String? ?? '🎉',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Group && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

