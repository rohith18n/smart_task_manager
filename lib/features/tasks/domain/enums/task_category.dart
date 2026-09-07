import 'package:flutter/material.dart';

enum TaskCategory {
  work('Work', Icons.work_outline, Color(0xFF2563EB), Color(0xFFEFF6FF)),
  personal('Personal', Icons.person_outline, Color(0xFF7C3AED), Color(0xFFF5F3FF)),
  health('Health', Icons.favorite_border, Color(0xFF059669), Color(0xFFECFDF5)),
  finance('Finance', Icons.account_balance_wallet_outlined, Color(0xFFD97706), Color(0xFFFFFBEB)),
  education('Education', Icons.school_outlined, Color(0xFF0284C7), Color(0xFFF0F9FF)),
  shopping('Shopping', Icons.shopping_bag_outlined, Color(0xFFDB2777), Color(0xFFFDF2F8)),
  travel('Travel', Icons.flight_takeoff_outlined, Color(0xFF0D9488), Color(0xFFF0FDFA)),
  others('Others', Icons.category_outlined, Color(0xFF64748B), Color(0xFFF8FAFC));

  final String displayName;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const TaskCategory(this.displayName, this.icon, this.color, this.backgroundColor);

  static TaskCategory fromString(String? value) {
    if (value == null) return TaskCategory.work;
    for (final category in TaskCategory.values) {
      if (category.displayName.toLowerCase() == value.toLowerCase()) {
        return category;
      }
    }
    return TaskCategory.work;
  }
}
