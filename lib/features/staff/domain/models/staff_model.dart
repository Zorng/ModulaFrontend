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

  Staff copyWith({
    String? userName,
    String? gender,
    String? phoneNumber,
    String? email,
    String? role,
    String? branch,
    String? scheduleOption,
    bool? isActive,
    Set<String>? workingDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Map<String, (TimeOfDay, TimeOfDay)>? customHours,
    List<ShiftScheduleEntry>? shiftSchedule,
    String? id,
    String? branchId,
    String? status,
    String? password,
  }) {
    return Staff(
      userName: userName ?? this.userName,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      scheduleOption: scheduleOption ?? this.scheduleOption,
      isActive: isActive ?? this.isActive,
      workingDays: workingDays ?? this.workingDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      customHours: customHours ?? this.customHours,
      shiftSchedule: shiftSchedule ?? this.shiftSchedule,
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      status: status ?? this.status,
      password: password ?? this.password,
    );
  }
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
