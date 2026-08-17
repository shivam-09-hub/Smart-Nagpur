enum ReviewStatus { pending, approved, rejected, moreInfoNeeded, onHold }

extension ReviewStatusDetails on ReviewStatus {
  String get label => switch (this) {
    ReviewStatus.pending => 'Pending',
    ReviewStatus.approved => 'Approved',
    ReviewStatus.rejected => 'Rejected',
    ReviewStatus.moreInfoNeeded => 'More Info Needed',
    ReviewStatus.onHold => 'On Hold',
  };

  bool get isPending => this == ReviewStatus.pending;
  bool get isApproved => this == ReviewStatus.approved;
  bool get isRejected => this == ReviewStatus.rejected;
}

class AdminReview {
  const AdminReview({
    required this.id,
    required this.itemType, // 'complaint' or 'application'
    required this.itemId,
    required this.reviewedBy,
    required this.status,
    required this.createdAt,
    this.comments = '',
    this.rating,
    this.attachmentNotes = '',
  });

  final String id;
  final String itemType;
  final String itemId;
  final String reviewedBy;
  final ReviewStatus status;
  final DateTime createdAt;
  final String comments;
  final int? rating;
  final String attachmentNotes;

  AdminReview copyWith({
    ReviewStatus? status,
    String? comments,
    int? rating,
    String? attachmentNotes,
  }) {
    return AdminReview(
      id: id,
      itemType: itemType,
      itemId: itemId,
      reviewedBy: reviewedBy,
      status: status ?? this.status,
      createdAt: createdAt,
      comments: comments ?? this.comments,
      rating: rating ?? this.rating,
      attachmentNotes: attachmentNotes ?? this.attachmentNotes,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'itemType': itemType,
    'itemId': itemId,
    'reviewedBy': reviewedBy,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'comments': comments,
    'rating': rating,
    'attachmentNotes': attachmentNotes,
  };

  factory AdminReview.fromJson(Map<String, Object?> json) {
    return AdminReview(
      id: json['id'] as String? ?? '',
      itemType: json['itemType'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      reviewedBy: json['reviewedBy'] as String? ?? '',
      status: ReviewStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ReviewStatus.pending,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      comments: json['comments'] as String? ?? '',
      rating: json['rating'] as int?,
      attachmentNotes: json['attachmentNotes'] as String? ?? '',
    );
  }
}
