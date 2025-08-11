import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/domain/entities/user_stats.dart';

abstract class ProfileRepo {
  Future<ProfileUser?> fetchUserProfile(String uid);
  Future<void> updateProfile(ProfileUser user);
  Future<List<ProfileUser>> searchUsers(String query);
  Future<UserStats> getUserStats(String uid);
  Future<void> followUser(String currentUserId, String targetUserId);
  Future<void> unfollowUser(String currentUserId, String targetUserId);
  Future<void> updateUserStats(String uid, UserStats stats);
  Future<List<ProfileUser>> getFollowers(String uid);
  Future<List<ProfileUser>> getFollowing(String uid);
}