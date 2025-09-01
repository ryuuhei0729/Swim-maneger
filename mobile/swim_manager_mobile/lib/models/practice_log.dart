class PracticeLog {
  final int id;
  final DateTime practiceDate;
  final String? title;
  final String? notes;
  final List<PracticeTime> practiceTimes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PracticeLog({
    required this.id,
    required this.practiceDate,
    this.title,
    this.notes,
    required this.practiceTimes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PracticeLog.fromJson(Map<String, dynamic> json) {
    return PracticeLog(
      id: json['id'],
      practiceDate: DateTime.parse(json['practice_date']),
      title: json['title'],
      notes: json['notes'],
      practiceTimes: (json['practice_times'] as List?)
          ?.map((time) => PracticeTime.fromJson(time))
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
      'practice_date': practiceDate.toIso8601String(),
      'title': title,
      'notes': notes,
      'practice_times': practiceTimes.map((time) => time.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDate {
    return '${practiceDate.year}/${practiceDate.month.toString().padLeft(2, '0')}/${practiceDate.day.toString().padLeft(2, '0')}';
  }

  double get totalDistance {
    return practiceTimes.fold(0.0, (sum, time) => sum + time.distance);
  }

  Duration get totalTime {
    return practiceTimes.fold(
      Duration.zero,
      (sum, time) => sum + time.duration,
    );
  }
}

class PracticeTime {
  final int id;
  final int distance;
  final Duration duration;
  final String? style;
  final String? notes;
  final DateTime createdAt;

  PracticeTime({
    required this.id,
    required this.distance,
    required this.duration,
    this.style,
    this.notes,
    required this.createdAt,
  });

  factory PracticeTime.fromJson(Map<String, dynamic> json) {
    return PracticeTime(
      id: json['id'],
      distance: json['distance'],
      duration: Duration(seconds: json['duration_seconds']),
      style: json['style'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'distance': distance,
      'duration_seconds': duration.inSeconds,
      'style': style,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    return '${distance}m';
  }

  double get pace {
    if (distance == 0) return 0;
    return duration.inSeconds / distance;
  }

  String get formattedPace {
    final paceMinutes = (pace / 60).floor();
    final paceSeconds = (pace % 60).round();
    return '${paceMinutes}:${paceSeconds.toString().padLeft(2, '0')}/100m';
  }
}
