import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/domain/entities/user_stats.dart';

abstract class ProfileStates {}

// Initial
class ProfileInitial extends ProfileStates {}

// Loading
class ProfileLoading extends ProfileStates {}

// Loaded
class ProfileLoaded extends ProfileStates {
  final ProfileUser profileUser;
  ProfileLoaded(this.profileUser);
}

// Search Results
class SearchResultsLoaded extends ProfileStates {
  final List<ProfileUser> users;
  SearchResultsLoaded(this.users);
}

// User Stats
class UserStatsLoaded extends ProfileStates {
  final String uid; // hangi kullanıcının istatistikleri
  final UserStats stats;
  UserStatsLoaded(this.uid, this.stats);
}

// Followers
class FollowersLoaded extends ProfileStates {
  final List<ProfileUser> users;
  FollowersLoaded(this.users);
}

// Following
class FollowingLoaded extends ProfileStates {
  final List<ProfileUser> users;
  FollowingLoaded(this.users);
}

// Follow Success
class FollowSuccess extends ProfileStates {}

// Unfollow Success
class UnfollowSuccess extends ProfileStates {}

// Error
class ProfileError extends ProfileStates {
  final String message;
  ProfileError(this.message);
}