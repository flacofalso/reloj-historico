class HistoricalEvent {
  final String id;
  final String time;
  final String date;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String imageCredits;
  final String source;
  final bool verified;

  HistoricalEvent({
    required this.id,
    required this.time,
    required this.date,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.imageCredits = '',
    this.source = '',
    this.verified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'date': date,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'imageCredits': imageCredits,
      'source': source,
      'verified': verified,
    };
  }

  factory HistoricalEvent.fromJson(Map<String, dynamic> json) {
    return HistoricalEvent(
      id: json['id'] ?? '',
      time: json['time'] ?? '00:00',
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      imageUrl: json['imageUrl'] ?? '',
      imageCredits: json['imageCredits'] ?? '',
      source: json['source'] ?? '',
      verified: json['verified'] ?? false,
    );
  }
}