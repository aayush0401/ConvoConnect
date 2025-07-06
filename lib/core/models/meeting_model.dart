class MeetingModel {
  final String id;
  final String meetingId;
  final String roomName;
  final String hostId;
  final String hostName;
  final DateTime createdAt;
  final DateTime? endedAt;
  final List<String> participants;
  final String status; // 'active', 'ended'
  final String? title;
  final int duration; // in seconds

  MeetingModel({
    required this.id,
    required this.meetingId,
    required this.roomName,
    required this.hostId,
    required this.hostName,
    required this.createdAt,
    this.endedAt,
    required this.participants,
    required this.status,
    this.title,
    this.duration = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'meetingId': meetingId,
      'roomName': roomName,
      'hostId': hostId,
      'hostName': hostName,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'participants': participants,
      'status': status,
      'title': title,
      'duration': duration,
    };
  }

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        return DateTime.parse(value);
      }
      // Handle Firestore Timestamp
      if (value.runtimeType.toString() == 'Timestamp') {
        return value.toDate();
      }
      return DateTime.now();
    }

    return MeetingModel(
      id: map['id'] ?? '',
      meetingId: map['meetingId'] ?? '',
      roomName: map['roomName'] ?? '',
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? '',
      createdAt: parseDateTime(map['createdAt']),
      endedAt: map['endedAt'] != null ? parseDateTime(map['endedAt']) : null,
      participants: List<String>.from(map['participants'] ?? []),
      status: map['status'] ?? 'active',
      title: map['title'],
      duration: map['duration'] ?? 0,
    );
  }

  MeetingModel copyWith({
    String? id,
    String? meetingId,
    String? roomName,
    String? hostId,
    String? hostName,
    DateTime? createdAt,
    DateTime? endedAt,
    List<String>? participants,
    String? status,
    String? title,
    int? duration,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      roomName: roomName ?? this.roomName,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      title: title ?? this.title,
      duration: duration ?? this.duration,
    );
  }
}
