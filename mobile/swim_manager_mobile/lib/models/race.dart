class Race {
  final int id;
  final String name;
  final DateTime? raceDate;
  final String venue;
  final String? description;
  final List<Event> events;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Race({
    required this.id,
    required this.name,
    this.raceDate,
    required this.venue,
    this.description,
    required this.events,
    required this.createdAt,
    this.updatedAt,
  });

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json['id'],
      name: json['name'],
      raceDate: json['race_date'] != null ? DateTime.tryParse(json['race_date']) : null,
      venue: json['venue'],
      description: json['description'],
      events: (json['events'] as List?)
          ?.map((event) => Event.fromJson(event))
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
      'name': name,
      'race_date': raceDate?.toIso8601String(),
      'venue': venue,
      'description': description,
      'events': events.map((event) => event.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDate {
    if (raceDate == null) return '大会日未設定';
    return '${raceDate!.year}/${raceDate!.month.toString().padLeft(2, '0')}/${raceDate!.day.toString().padLeft(2, '0')}';
  }

  bool get isUpcoming {
    if (raceDate == null) return false;
    return raceDate!.isAfter(DateTime.now());
  }

  bool get isToday {
    if (raceDate == null) return false;
    final now = DateTime.now();
    return raceDate!.year == now.year &&
           raceDate!.month == now.month &&
           raceDate!.day == now.day;
  }
}

class Event {
  final int id;
  final String name;
  final int distance;
  final String style;
  final String? gender;
  final String? ageGroup;
  final List<Entry> entries;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.name,
    required this.distance,
    required this.style,
    this.gender,
    this.ageGroup,
    required this.entries,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      distance: json['distance'],
      style: json['style'],
      gender: json['gender'],
      ageGroup: json['age_group'],
      entries: (json['entries'] as List?)
          ?.map((entry) => Entry.fromJson(entry))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'distance': distance,
      'style': style,
      'gender': gender,
      'age_group': ageGroup,
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDistance {
    return '${distance}m';
  }

  String get fullName {
    return '${distance}m $style';
  }
}

class Entry {
  final int id;
  final int userId;
  final String userName;
  final String status; // 'registered', 'confirmed', 'completed'
  final Duration? time;
  final int? rank;
  final DateTime createdAt;

  Entry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.status,
    this.time,
    this.rank,
    required this.createdAt,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      status: json['status'],
      time: (json['time_seconds'] as num?) != null
          ? Duration(milliseconds: ((json['time_seconds'] as num) * 1000).round())
          : null,
      rank: json['rank'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'status': status,
      // 秒(小数)で書き戻す。精度維持のためミリ秒から変換
      'time_seconds': time != null ? time!.inMilliseconds / 1000.0 : null,
      'rank': rank,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    if (time == null) return '-';
    var totalMs = time!.inMilliseconds;
    var minutes = totalMs ~/ 60000;
    var seconds = (totalMs % 60000) ~/ 1000;
    var centi = ((totalMs % 1000) / 10).round(); // 0..100
    if (centi == 100) { centi = 0; seconds += 1; }
    if (seconds == 60) { seconds = 0; minutes += 1; }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centi.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status) {
      case 'registered':
        return 'エントリー済み';
      case 'confirmed':
        return '確認済み';
      case 'completed':
        return '完了';
      default:
        return '不明';
    }
  }
}
