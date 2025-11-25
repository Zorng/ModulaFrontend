import 'package:flutter/material.dart';

class Staff {
  final String userName;
  final String? gender;
  final String phoneNumber;
  final String email;
  final String? role;
  final String? branch;
  final String? scheduleOption;
  final bool isActive;
  final Set<String>? workingDays;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Map<String, (TimeOfDay, TimeOfDay)>? customHours;

  Staff({
    required this.userName,
    this.gender,
    required this.phoneNumber,
    required this.email,
    this.role,
    this.branch,
    this.scheduleOption,
    required this.isActive,
    this.workingDays,
    this.startTime,
    this.endTime,
    this.customHours,
  });
}
