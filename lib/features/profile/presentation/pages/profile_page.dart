import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/home/presentation/components/post_tile.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/domain/entities/user_stats.dart';
import 'package:social/features/profile/presentation/components/bio_box.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';
import 'package:social/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:social/features/profile/presentation/pages/followers_page.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool isOwnProfile;
  ProfileUser? currentProfileUser;
  UserStats? userStats;
  UserStats? currentUserStats; // Takip eden kişinin istatistikleri
  bool isFollowing = false;
  bool isLoadingProfile = true;
  bool isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthCubit>().currentUser;
    isOwnProfile = currentUser?.uid == widget.uid;
    
    _loadProfileData();
  }

  void _loadProfileData() {
    final currentUser = context.read<AuthCubit>().currentUser;
    
    // Profil bilgilerini yükle
    context.read<ProfileCubit>().fetchUserProfile(widget.uid);
    // Kullanıcı istatistiklerini yükle
    context.read<ProfileCubit>().getUserStats(widget.uid);
    // Postları yükle
    context.read<PostCubit>().fetchUserPosts(widget.uid);
    
    // Eğer kendi profili değilse, kendi istatistiklerini de yükle
    if (!isOwnProfile && currentUser != null) {
      _loadCurrentUserStats(currentUser.uid);
    }
  }

  void _loadCurrentUserStats(String currentUserId) async {
    try {
      final profileCubit = context.read<ProfileCubit>();
      // Mevcut kullanıcının istatistiklerini al
      await profileCubit.getUserStats(currentUserId);
    } catch (e) {
      print('Current user stats loading error: $e');
    }
  }

  void _toggleFollow() {
    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null || currentProfileUser == null) return;

    if (isFollowing) {
      context.read<ProfileCubit>().unfollowUser(currentUser.uid, widget.uid);
    } else {
      context.read<ProfileCubit>().followUser(currentUser.uid, widget.uid);
    }
  }

  void _showFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersPage(
          uid: widget.uid,
          title: "Takipçiler",
          isFollowers: true,
        ),
      ),
    );
  }

  void _showFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersPage(
          uid: widget.uid,
          title: "Takip Edilenler",
          isFollowers: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? "Profil" : "Kullanıcı Profili"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          if (isOwnProfile)
            IconButton(
              onPressed: () {
                if (currentProfileUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(user: currentProfileUser!),
                    ),
                  );
                }
              },
              icon: Icon(Icons.settings),
            ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProfileCubit, ProfileStates>(
            listener: (context, state) {
              if (state is ProfileLoaded) {
                setState(() {
                  currentProfileUser = state.profileUser;
                  isLoadingProfile = false;
                });
              } else if (state is UserStatsLoaded) {
                final currentUser = context.read<AuthCubit>().currentUser;
                // state.uid hangi kullanıcının istatistiği geldiğini söylüyor
                if (state.uid == widget.uid) {
                  // Görüntülenen profilin istatistikleri
                  setState(() {
                    userStats = state.stats;
                    if (currentUser != null) {
                      isFollowing = state.stats.followers.contains(currentUser.uid);
                    }
                  });
                } else if (currentUser != null && state.uid == currentUser.uid) {
                  // Mevcut kullanıcının istatistikleri (takip eden kişi)
                  setState(() {
                    currentUserStats = state.stats;
                  });
                }
              } else if (state is FollowSuccess || state is UnfollowSuccess) {
                // Takip işlemi başarılı, her iki kullanıcının istatistiklerini yenile
                final currentUser = context.read<AuthCubit>().currentUser;
                if (currentUser != null) {
                  context.read<ProfileCubit>().getUserStats(widget.uid);
                  context.read<ProfileCubit>().getUserStats(currentUser.uid);
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state is FollowSuccess ? "Takip edildi!" : "Takipten çıkıldı!"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              } else if (state is ProfileError) {
                setState(() {
                  isLoadingProfile = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<PostCubit, PostStates>(
            listener: (context, state) {
              if (state is PostsLoaded || state is PostsError) {
                setState(() {
                  isLoadingPosts = false;
                });
              }
            },
          ),
        ],
        child: isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : currentProfileUser == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Kullanıcı bulunamadı"),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Geri Dön"),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _loadProfileData();
                    },
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Profil bilgileri
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Profil resmi ve istatistikler
                                Row(
                                  children: [
                                    // Profil resmi
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage: currentProfileUser!.profileImageUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(currentProfileUser!.profileImageUrl)
                                          : null,
                                      child: currentProfileUser!.profileImageUrl.isEmpty
                                          ? Text(
                                              currentProfileUser!.name.isNotEmpty 
                                                  ? currentProfileUser!.name[0].toUpperCase() 
                                                  : '?',
                                              style: TextStyle(fontSize: 32),
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 20),
                                    // İstatistikler
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          BlocBuilder<PostCubit, PostStates>(
                                            builder: (context, postState) {
                                              int postCount = 0;
                                              if (postState is PostsLoaded) {
                                                postCount = postState.posts.length;
                                              }
                                              return _buildStatColumn(
                                                "Gönderiler", 
                                                postCount.toString(),
                                                onTap: null,
                                              );
                                            },
                                          ),
                                          _buildStatColumn(
                                            "Takipçi", 
                                            userStats?.followersCount.toString() ?? "0",
                                            onTap: _showFollowers,
                                          ),
                                          _buildStatColumn(
                                            "Takip", 
                                            userStats?.followingCount.toString() ?? "0",
                                            onTap: _showFollowing,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Kullanıcı adı
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    currentProfileUser!.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Email
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    currentProfileUser!.email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                // Bio
                                BioBox(text: currentProfileUser!.bio),
                                SizedBox(height: 16),
                                // Takip butonu (eğer kendi profili değilse)
                                if (!isOwnProfile)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _toggleFollow,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFollowing 
                                            ? Colors.grey 
                                            : Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        isFollowing ? "Takipten Çık" : "Takip Et",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Divider(),
                          // Posts başlığı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "Gönderiler",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Kullanıcının postları
                          BlocBuilder<PostCubit, PostStates>(
                            builder: (context, postState) {
                              if (isLoadingPosts) {
                                return const Padding(
                                  padding: EdgeInsets.all(50.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              if (postState is PostsError) {
                                return Padding(
                                  padding: const EdgeInsets.all(50.0),
                                  child: Center(
                                    child: Text(
                                      "Postlar yüklenirken hata oluştu",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                );
                              }

                              if (postState is PostsLoaded) {
                                final posts = postState.posts;
                                if (posts.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(50.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.photo, size: 64, color: Colors.grey[400]),
                                          SizedBox(height: 16),
                                          Text(
                                            "Henüz gönderi yok",
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return Column(
                                  children: posts.map((post) {
                                    return PostTile(
                                      post: post,
                                      postUser: currentProfileUser,
                                      onDeletePressed: isOwnProfile
                                          ? () => context.read<PostCubit>().deletePost(post.id)
                                          : null,
                                    );
                                  }).toList(),
                                );
                              }

                              return const SizedBox();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}