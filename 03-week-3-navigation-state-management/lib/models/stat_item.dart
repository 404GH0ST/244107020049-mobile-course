import 'package:flutter/material.dart';

class StatItem {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const StatItem({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });
}
