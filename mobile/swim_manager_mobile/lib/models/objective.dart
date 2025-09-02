import 'package:flutter/material.dart';

class Objective {
  final int id;
  final String title;
  final String description;
  final DateTime? targetDate;
  final String status; // 'active', 'completed', 'cancelled'
  final double progress; // 0.0 to 1.0
  final List<Milestone> milestones;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Objective({
    required this.id,
    required this.title,
    required this.description,
    this.targetDate,
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
      targetDate: _parseTargetDate(json),
      status: _parseStatus(json),
      progress: _parseProgress(json),
      milestones: _parseMilestones(json),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  // ヘルパーメソッド: ターゲット日付のパース（target_date または target_time）
  static DateTime? _parseTargetDate(Map<String, dynamic> json) {
    final targetDate = json['target_date'] ?? json['target_time'];
    if (targetDate != null) {
      return DateTime.tryParse(targetDate);
    }
    return null;
  }

  // ヘルパーメソッド: ステータスのパース（status または attendance_event）
  static String _parseStatus(Map<String, dynamic> json) {
    final status = json['status'] ?? json['attendance_event'];
    if (status != null) {
      // attendance_event から status への軽量マッピング
      if (status == 'present') return 'active';
      if (status == 'absent') return 'cancelled';
      if (status == 'other') return 'active';
      return status;
    }
    return 'active'; // デフォルト値
  }

  // ヘルパーメソッド: 進捗のパース（progress または completion）
  static double _parseProgress(Map<String, dynamic> json) {
    final progress = json['progress'] ?? json['completion'];
    if (progress != null) {
      return progress.toDouble();
    }
    return 0.0; // デフォルト値
  }

  // ヘルパーメソッド: マイルストーンのパース
  static List<Milestone> _parseMilestones(Map<String, dynamic> json) {
    final milestones = json['milestones'] as List?;
    if (milestones != null) {
      return milestones
          .map((milestone) => Milestone.fromJson(milestone))
          .toList();
    }
    return [];
  }

  // ヘルパーメソッド: DateTime の安全なパース
  static DateTime? _parseDateTime(dynamic value) {
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target_date': targetDate?.toIso8601String(),
      'status': status,
      'progress': progress,
      'milestones': milestones.map((milestone) => milestone.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedTargetDate {
    if (targetDate == null) return '目標日未設定';
    return '${targetDate!.year}/${targetDate!.month.toString().padLeft(2, '0')}/${targetDate!.day.toString().padLeft(2, '0')}';
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
    if (targetDate == null) return false;
    return targetDate!.isBefore(DateTime.now()) && status == 'active';
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
  final bool isOverdueField;
  final int? daysRemaining;

  Milestone({
    required this.id,
    required this.title,
    this.description,
    required this.targetDate,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
    this.isOverdueField = false,
    this.daysRemaining,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      title: _parseMilestoneTitle(json),
      description: _parseMilestoneDescription(json),
      targetDate: _parseMilestoneDate(json),
      isCompleted: json['is_completed'] ?? false,
      completedAt: _parseDateTime(json['completed_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      isOverdueField: json['is_overdue'] ?? false,
      daysRemaining: json['days_remaining'],
    );
  }

  // ヘルパーメソッド: マイルストーンのタイトルパース（milestone_type_label または title）
  static String _parseMilestoneTitle(Map<String, dynamic> json) {
    return json['milestone_type_label'] ?? json['title'] ?? 'マイルストーン';
  }

  // ヘルパーメソッド: マイルストーンの説明パース（note または description）
  static String? _parseMilestoneDescription(Map<String, dynamic> json) {
    return json['note'] ?? json['description'];
  }

  // ヘルパーメソッド: マイルストーンの日付パース（limit_date を優先、次に target_date、最後に due_date）
  static DateTime _parseMilestoneDate(Map<String, dynamic> json) {
    final targetDate = json['limit_date'] ?? json['target_date'] ?? json['due_date'];
    if (targetDate != null) {
      final parsed = DateTime.tryParse(targetDate);
      if (parsed != null) return parsed;
    }
    return DateTime.now(); // デフォルト値
  }

  // ヘルパーメソッド: DateTime の安全なパース
  static DateTime? _parseDateTime(dynamic value) {
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
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
      'is_overdue': isOverdueField,
      'days_remaining': daysRemaining,
    };
  }

  String get formattedTargetDate {
    return '${targetDate.year}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.day.toString().padLeft(2, '0')}';
  }

  bool get isOverdue {
    // フィールドの値が設定されている場合はそれを使用、そうでなければ計算
    if (isOverdueField) return true;
    return targetDate.isBefore(DateTime.now()) && !isCompleted;
  }
}
