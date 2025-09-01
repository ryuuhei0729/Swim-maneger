import 'package:flutter/material.dart';

class Objective {
  final int id;
  final String title;
  final String description;
  final DateTime targetDate;
  final String status; // 'active', 'completed', 'cancelled'
  final double progress; // 0.0 to 1.0
  final List<Milestone> milestones;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Objective({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.status,
    required this.progress,
    required this.milestones,
    required this.createdAt,
    this.updatedAt,
  });

  factory Objective.fromJson(Map<String, dynamic> json) {
    return Objective(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetDate: DateTime.parse(json['target_date']),
      status: json['status'],
      progress: (json['progress'] ?? 0.0).toDouble(),
      milestones: (json['milestones'] as List?)
          ?.map((milestone) => Milestone.fromJson(milestone))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_date': targetDate.toIso8601String(),
      'status': status,
      'progress': progress,
      'milestones': milestones.map((milestone) => milestone.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedTargetDate {
    return '${targetDate.year}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.day.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status) {
      case 'active':
        return '進行中';
      case 'completed':
        return '完了';
      case 'cancelled':
        return 'キャンセル';
      default:
        return '不明';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int get progressPercentage {
    return (progress * 100).round();
  }

  bool get isOverdue {
    return targetDate.isBefore(DateTime.now()) && status == 'active';
  }

  bool get isCompleted {
    return status == 'completed';
  }
}

class Milestone {
  final int id;
  final String title;
  final String? description;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  Milestone({
    required this.id,
    required this.title,
    this.description,
    required this.targetDate,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetDate: DateTime.parse(json['target_date']),
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_date': targetDate.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTargetDate {
    return '${targetDate.year}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.day.toString().padLeft(2, '0')}';
  }

  bool get isOverdue {
    return targetDate.isBefore(DateTime.now()) && !isCompleted;
  }
}
