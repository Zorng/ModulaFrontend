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
  final List<ShiftScheduleEntry>? shiftSchedule;
  final String? id;
  final String? branchId;
  final String? status;
  final String? password;

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
    this.shiftSchedule,
    this.id,
    this.branchId,
    this.status,
    this.password,
  });
}

class ShiftScheduleEntry {
  const ShiftScheduleEntry({
    required this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.isOff = false,
  });

  final int dayOfWeek; // 0=Sun ... 6=Sat
  final String? startTime; // "HH:MM" or "HH:MM:SS"
  final String? endTime;
  final bool isOff;
}
