import 'package:flutter/material.dart';

import '../../core/config/constants.dart';

String supportStatusLabel(String status) {
  return switch (status) {
    'in_progress' => 'In progress',
    'resolved' => 'Resolved',
    _ => 'Open',
  };
}

Color supportStatusColor(String status) {
  return switch (status) {
    'resolved' => const Color(AppColors.textSecondaryColor),
    'in_progress' => const Color(AppColors.primaryColor),
    _ => const Color(AppColors.accentColor),
  };
}

bool isActiveSupportStatus(String status) =>
    status == 'open' || status == 'in_progress';
