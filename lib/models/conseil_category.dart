import 'package:flutter/material.dart';

class ConseilCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> items;

  ConseilCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'icon': icon.codePoint,
      'color': color.value,
      'items': items,
    };
  }

  factory ConseilCategory.fromJson(Map<String, dynamic> json) {
    return ConseilCategory(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      items: List<String>.from(json['items']),
    );
  }
}