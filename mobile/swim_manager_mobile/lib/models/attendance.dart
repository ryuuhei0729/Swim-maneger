import 'package:flutter/material.dart';

class Attendance {
  final int id;
  final DateTime date;
  final String status; // 'present', 'absent', 'late', 'excused'
  final String? reason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Attendance({
    required this.id,
    required this.date,
    required this.status,
    this.reason,
    required this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'status': status,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDate {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status) {
      case 'present':
        return '出席';
      case 'absent':
        return '欠席';
      case 'late':
        return '遅刻';
      case 'excused':
        return '公欠';
      default:
        return '不明';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class AttendanceEvent {
  final int id;
  final String title;
  final DateTime date;
  final String? description;
  final List<Attendance> attendances;
  final DateTime createdAt;

  AttendanceEvent({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    required this.attendances,
    required this.createdAt,
  });

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    return AttendanceEvent(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      attendances: (json['attendances'] as List?)
          ?.map((attendance) => Attendance.fromJson(attendance))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'attendances': attendances.map((attendance) => attendance.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  int get presentCount {
    return attendances.where((a) => a.status == 'present').length;
  }

  int get absentCount {
    return attendances.where((a) => a.status == 'absent').length;
  }

  int get lateCount {
    return attendances.where((a) => a.status == 'late').length;
  }

  int get excusedCount {
    return attendances.where((a) => a.status == 'excused').length;
  }

  double get attendanceRate {
    if (attendances.isEmpty) return 0.0;
    final present = presentCount + lateCount;
    return (present / attendances.length) * 100;
  }
}
