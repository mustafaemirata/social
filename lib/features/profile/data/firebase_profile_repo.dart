import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/domain/entities/user_stats.dart';
import 'package:social/features/profile/domain/repos/profile_repo.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      return ProfileUser.fromJson(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Profil bilgileri alınamadı: $e');
    }
  }

  @override
  Future<void> updateProfile(ProfileUser user) async {
    try {
      await firestore.collection('users').doc(user.uid).update(user.toJson());
    } catch (e) {
      throw Exception('Profil güncellenemedi: $e');
    }
  }

  @override
  Future<List<ProfileUser>> searchUsers(String query) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThan: '${query.toLowerCase()}z')
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => ProfileUser.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı araması başarısız: $e');
    }
  }

  @override
  Future<UserStats> getUserStats(String uid) async {
    try {
      final statsDoc = await firestore.collection('user_stats').doc(uid).get();
      if (!statsDoc.exists) {
        // İlk kez stats oluştur
        final newStats = UserStats();
        await firestore.collection('user_stats').doc(uid).set(newStats.toJson());
        return newStats;
      }
      return UserStats.fromJson(statsDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Kullanıcı istatistikleri alınamadı: $e');
    }
  }

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final batch = firestore.batch();
      
      // Current user's stats
      final currentUserStatsRef = firestore.collection('user_stats').doc(currentUserId);
      final currentUserStats = await getUserStats(currentUserId);
      
      // Target user's stats
      final targetUserStatsRef = firestore.collection('user_stats').doc(targetUserId);
      final targetUserStats = await getUserStats(targetUserId);

      // Update current user's following
      final updatedCurrentStats = currentUserStats.copyWith(
        following: [...currentUserStats.following, targetUserId],
        followingCount: currentUserStats.followingCount + 1,
      );
      
      // Update target user's followers
      final updatedTargetStats = targetUserStats.copyWith(
        followers: [...targetUserStats.followers, currentUserId],
        followersCount: targetUserStats.followersCount + 1,
      );

      batch.set(currentUserStatsRef, updatedCurrentStats.toJson());
      batch.set(targetUserStatsRef, updatedTargetStats.toJson());

      await batch.commit();
    } catch (e) {
      throw Exception('Takip etme işlemi başarısız: $e');
    }
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final batch = firestore.batch();
      
      // Current user's stats
      final currentUserStatsRef = firestore.collection('user_stats').doc(currentUserId);
      final currentUserStats = await getUserStats(currentUserId);
      
      // Target user's stats
      final targetUserStatsRef = firestore.collection('user_stats').doc(targetUserId);
      final targetUserStats = await getUserStats(targetUserId);

      // Update current user's following
      final updatedCurrentStats = currentUserStats.copyWith(
        following: currentUserStats.following.where((id) => id != targetUserId).toList(),
        followingCount: currentUserStats.followingCount > 0 ? currentUserStats.followingCount - 1 : 0,
      );
      
      // Update target user's followers
      final updatedTargetStats = targetUserStats.copyWith(
        followers: targetUserStats.followers.where((id) => id != currentUserId).toList(),
        followersCount: targetUserStats.followersCount > 0 ? targetUserStats.followersCount - 1 : 0,
      );

      batch.set(currentUserStatsRef, updatedCurrentStats.toJson());
      batch.set(targetUserStatsRef, updatedTargetStats.toJson());

      await batch.commit();
    } catch (e) {
      throw Exception('Takipten çıkma işlemi başarısız: $e');
    }
  }

  @override
  Future<void> updateUserStats(String uid, UserStats stats) async {
    try {
      await firestore.collection('user_stats').doc(uid).set(stats.toJson());
    } catch (e) {
      throw Exception('Kullanıcı istatistikleri güncellenemedi: $e');
    }
  }

  @override
  Future<List<ProfileUser>> getFollowers(String uid) async {
    try {
      final stats = await getUserStats(uid);
      final followers = <ProfileUser>[];
      
      for (String followerId in stats.followers) {
        final user = await fetchUserProfile(followerId);
        if (user != null) {
          followers.add(user);
        }
      }
      
      return followers;
    } catch (e) {
      throw Exception('Takipçiler alınamadı: $e');
    }
  }

  @override
  Future<List<ProfileUser>> getFollowing(String uid) async {
    try {
      final stats = await getUserStats(uid);
      final following = <ProfileUser>[];
      
      for (String followingId in stats.following) {
        final user = await fetchUserProfile(followingId);
        if (user != null) {
          following.add(user);
        }
      }
      
      return following;
    } catch (e) {
      throw Exception('Takip edilenler alınamadı: $e');
    }
  }
}