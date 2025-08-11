import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';
import 'package:social/features/profile/presentation/pages/profile_page.dart';

class FollowersPage extends StatefulWidget {
  final String uid;
  final String title;
  final bool isFollowers; // true = takipçiler, false = takip edilenler
  
  const FollowersPage({
    super.key,
    required this.uid,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  List<ProfileUser> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final profileCubit = context.read<ProfileCubit>();
      if (widget.isFollowers) {
        await profileCubit.getFollowers(widget.uid);
      } else {
        await profileCubit.getFollowing(widget.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: BlocListener<ProfileCubit, ProfileStates>(
        listener: (context, state) {
          if (state is FollowersLoaded) {
            setState(() {
              users = state.users;
              isLoading = false;
            });
          } else if (state is FollowingLoaded) {
            setState(() {
              users = state.users;
              isLoading = false;
            });
          } else if (state is ProfileError) {
            setState(() {
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          widget.isFollowers 
                              ? 'Henüz takipçi yok'
                              : 'Henüz kimseyi takip etmiyor',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _loadUsers();
                    },
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: user.profileImageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(user.profileImageUrl)
                                  : null,
                              child: user.profileImageUrl.isEmpty
                                  ? Text(
                                      user.name.isNotEmpty 
                                          ? user.name[0].toUpperCase() 
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              user.bio.isNotEmpty ? user.bio : user.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(uid: user.uid),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
