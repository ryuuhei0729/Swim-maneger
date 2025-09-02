class PracticeLog {
  final int id;
  final DateTime? practiceDate;
  final String? title;
  final String? notes;
  final List<PracticeTime> practiceTimes;
  final double? totalDistanceField;
  final Duration? totalTimeField;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PracticeLog({
    required this.id,
    this.practiceDate,
    this.title,
    this.notes,
    required this.practiceTimes,
    this.totalDistanceField,
    this.totalTimeField,
    required this.createdAt,
    this.updatedAt,
  });

  factory PracticeLog.fromJson(Map<String, dynamic> json) {
    return PracticeLog(
      id: json['id'],
      practiceDate: json['practice_date'] != null ? DateTime.tryParse(json['practice_date']) : null,
      title: json['event_title'], // バックエンドのevent_titleフィールドから読み取り
      notes: json['notes'],
      practiceTimes: (json['practice_times'] as List?)
          ?.map((time) => PracticeTime.fromJson(time))
          .toList() ?? [],
      totalDistanceField: json['total_distance']?.toDouble(),
      totalTimeField: json['total_time'] != null ? Duration(seconds: json['total_time']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'practice_date': practiceDate?.toIso8601String(),
      'event_title': title, // バックエンドのevent_titleフィールドとして書き込み
      'notes': notes,
      'practice_times': practiceTimes.map((time) => time.toJson()).toList(),
      'total_distance': totalDistanceField,
      'total_time': totalTimeField?.inSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDate {
    if (practiceDate == null) return '練習日未設定';
    return '${practiceDate!.year}/${practiceDate!.month.toString().padLeft(2, '0')}/${practiceDate!.day.toString().padLeft(2, '0')}';
  }

  double get totalDistance {
    // バックエンドフィールドが存在する場合はそれを使用、そうでなければ計算
    if (totalDistanceField != null) return totalDistanceField!;
    return practiceTimes.fold(0.0, (sum, time) => sum + time.distance);
  }

  Duration get totalTime {
    // バックエンドフィールドが存在する場合はそれを使用、そうでなければ計算
    if (totalTimeField != null) return totalTimeField!;
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
    if (distance == 0) return '0:00/100m';
    
    // pace（1メートルあたりの秒数）に100を掛けて100メートルあたりの秒数に変換
    final totalSeconds = (pace * 100).round();
    
    // 分と秒に変換
    var minutes = totalSeconds ~/ 60;
    var seconds = totalSeconds % 60;
    
    // 秒が60になった場合の処理
    if (seconds == 60) {
      minutes += 1;
      seconds = 0;
    }
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}/100m';
  }
}
