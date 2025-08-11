import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/domain/entities/user_stats.dart';
import 'package:social/features/profile/domain/repos/profile_repo.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';
import 'package:social/features/storage/domain/storage_repo.dart';
import 'dart:typed_data';

class ProfileCubit extends Cubit<ProfileStates> {
  final ProfileRepo profileRepo;
  final StorageRepo storageRepo;
  
  ProfileCubit({
    required this.profileRepo,
    required this.storageRepo,
  }) : super(ProfileInitial());

  // Kullanıcı profilini getir
  Future<void> fetchUserProfile(String uid) async {
    try {
      emit(ProfileLoading());
      final user = await profileRepo.fetchUserProfile(uid);
      
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileError("Kullanıcı bulunamadı!"));
      }
    } catch (e) {
      emit(ProfileError("Profil yüklenirken hata oluştu: ${e.toString()}"));
    }
  }

  // Kullanıcı ara
  Future<void> searchUsers(String query) async {
    try {
      emit(ProfileLoading());
      final users = await profileRepo.searchUsers(query);
      emit(SearchResultsLoaded(users));
    } catch (e) {
      emit(ProfileError("Arama yapılırken hata oluştu: ${e.toString()}"));
    }
  }

  // Kullanıcı istatistiklerini getir
  Future<void> getUserStats(String uid) async {
    try {
      final stats = await profileRepo.getUserStats(uid);
      emit(UserStatsLoaded(uid, stats));
    } catch (e) {
      emit(ProfileError("İstatistikler yüklenirken hata oluştu: ${e.toString()}"));
    }
  }

  // Takipçileri getir
  Future<void> getFollowers(String uid) async {
    try {
      emit(ProfileLoading());
      final followers = await profileRepo.getFollowers(uid);
      emit(FollowersLoaded(followers));
    } catch (e) {
      emit(ProfileError("Takipçiler yüklenirken hata oluştu: ${e.toString()}"));
    }
  }

  // Takip edilenleri getir
  Future<void> getFollowing(String uid) async {
    try {
      emit(ProfileLoading());
      final following = await profileRepo.getFollowing(uid);
      emit(FollowingLoaded(following));
    } catch (e) {
      emit(ProfileError("Takip edilenler yüklenirken hata oluştu: ${e.toString()}"));
    }
  }

  // Takip et
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await profileRepo.followUser(currentUserId, targetUserId);
      emit(FollowSuccess());
      
      // iki tarafın istatistiklerini yükle
      final targetStats = await profileRepo.getUserStats(targetUserId);
      emit(UserStatsLoaded(targetUserId, targetStats));
      final currentStats = await profileRepo.getUserStats(currentUserId);
      emit(UserStatsLoaded(currentUserId, currentStats));
      
    } catch (e) {
      emit(ProfileError("Takip etme işlemi başarısız: ${e.toString()}"));
    }
  }

  // Takipten çık
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await profileRepo.unfollowUser(currentUserId, targetUserId);
      emit(UnfollowSuccess());
      
      final targetStats = await profileRepo.getUserStats(targetUserId);
      emit(UserStatsLoaded(targetUserId, targetStats));
      final currentStats = await profileRepo.getUserStats(currentUserId);
      emit(UserStatsLoaded(currentUserId, currentStats));
      
    } catch (e) {
      emit(ProfileError("Takipten çıkma işlemi başarısız: ${e.toString()}"));
    }
  }

  // Profili güncelle
  Future<void> updateProfile({
    required String uid,
    String? newBio,
    Uint8List? imageWebBytes,
    String? imageMobilePath,
  }) async {
    emit(ProfileLoading());
    try {
      // Mevcut profili al
      final currentUser = await profileRepo.fetchUserProfile(uid);
      if (currentUser == null) {
        emit(ProfileError("Kullanıcı bulunamadı!"));
        return;
      }

      // Profil resmi güncelle
      String? imageDownloadUrl;
      if (imageWebBytes != null || imageMobilePath != null) {
        if (imageMobilePath != null) {
          imageDownloadUrl = await storageRepo.uploadProfileImageMobile(
            imageMobilePath,
            uid,
          );
        } else if (imageWebBytes != null) {
          imageDownloadUrl = await storageRepo.uploadProfileImageWeb(
            imageWebBytes,
            uid,
          );
        }
        
        if (imageDownloadUrl == null) {
          emit(ProfileError("Yükleme başarısız oldu!"));
          return;
        }
      }

      // Güncellenmiş profil
      final updatedProfile = currentUser.copyWith(
        newBio: newBio ?? currentUser.bio,
        newProfileImageUrl: imageDownloadUrl ?? currentUser.profileImageUrl,
      );

      // Profili güncelle
      await profileRepo.updateProfile(updatedProfile);
      
      // Güncellenmiş profili yükle
      await fetchUserProfile(uid);
    } catch (e) {
      emit(ProfileError("Güncelleme hatası: ${e.toString()}"));
    }
  }
}