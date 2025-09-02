import 'package:flutter/material.dart';

class Attendance {
  final int id;
  final DateTime? date;
  final String status; // 'present', 'absent', 'other'
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Attendance({
    required this.id,
    this.date,
    required this.status,
    this.note,
    required this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      status: json['status'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'status': status,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDate {
    if (date == null) return '日付未設定';
    return '${date!.year}/${date!.month.toString().padLeft(2, '0')}/${date!.day.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status) {
      case 'present':
        return '出席';
      case 'absent':
        return '欠席';
      case 'other':
        return 'その他';
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
      case 'other':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class AttendanceEvent {
  final int id;
  final String title;
  final DateTime? date;
  final String? description;
  final List<Attendance> attendances;
  final DateTime createdAt;

  AttendanceEvent({
    required this.id,
    required this.title,
    this.date,
    this.description,
    required this.attendances,
    required this.createdAt,
  });

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    return AttendanceEvent(
      id: json['id'],
      title: json['title'],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
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
      'date': date?.toIso8601String(),
      'description': description,
      'attendances': attendances.map((attendance) => attendance.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    if (date == null) return '日付未設定';
    return '${date!.year}/${date!.month.toString().padLeft(2, '0')}/${date!.day.toString().padLeft(2, '0')}';
  }

  int get presentCount {
    return attendances.where((a) => a.status == 'present').length;
  }

  int get absentCount {
    return attendances.where((a) => a.status == 'absent').length;
  }

  int get otherCount {
    return attendances.where((a) => a.status == 'other').length;
  }

  double get attendanceRate {
    if (attendances.isEmpty) return 0.0;
    final present = presentCount;
    return (present / attendances.length) * 100;
  }
}
