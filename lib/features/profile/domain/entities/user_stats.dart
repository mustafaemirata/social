class UserStats {
  final int postCount;
  final int followersCount;
  final int followingCount;
  final List<String> followers;
  final List<String> following;

  UserStats({
    this.postCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.followers = const [],
    this.following = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'postCount': postCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'followers': followers,
      'following': following,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      postCount: json['postCount'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
    );
  }

  UserStats copyWith({
    int? postCount,
    int? followersCount,
    int? followingCount,
    List<String>? followers,
    List<String>? following,
  }) {
    return UserStats(
      postCount: postCount ?? this.postCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
}
