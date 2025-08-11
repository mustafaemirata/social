import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:social/features/posts/presentation/pages/comments_page.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:intl/intl.dart';
import 'package:social/features/profile/presentation/pages/profile_page.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final void Function()? onDeletePressed;
  final ProfileUser? postUser;
  const PostTile({
    super.key,
    required this.post,
    required this.onDeletePressed,
    this.postUser,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  late Post _currentPost;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    context.read<ProfileCubit>().fetchUserProfile(widget.post.userId);
  }

  @override
  void didUpdateWidget(PostTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _currentPost = widget.post;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('dd.MM.yyyy HH:mm').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void showOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Gönderiyi silmek mi istiyorsunuz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              if (widget.onDeletePressed != null) {
                widget.onDeletePressed!();
              }
              Navigator.of(context).pop();
            },
            child: Text(
              "Sil",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike() {
    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null) return;

    final postCubit = context.read<PostCubit>();
    if (_currentPost.likes.contains(currentUser.uid)) {
      postCubit.unlikePost(_currentPost.id, currentUser.uid);
    } else {
      postCubit.likePost(_currentPost.id, currentUser.uid);
    }
  }

  void _openComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(post: _currentPost),
      ),
    ).then((_) {
      // Yorumlar sayfasından döndüğünde postları yenile
      context.read<PostCubit>().fetcjAllPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;
    final isLiked = currentUser != null && _currentPost.likes.contains(currentUser.uid);

    return BlocListener<PostCubit, PostStates>(
      listener: (context, state) {
        if (state is PostsLoaded) {
          // Post güncellendiğinde current post'u güncelle
          final updatedPost = state.posts.firstWhere(
            (post) => post.id == _currentPost.id,
            orElse: () => _currentPost,
          );
          if (mounted) {
            setState(() {
              _currentPost = updatedPost;
            });
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgisi ve silme butonu
            ListTile(
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(uid: _currentPost.userId),
                    ),
                  );
                },
                child: CircleAvatar(
                backgroundImage: widget.postUser?.profileImageUrl != null &&
                        widget.postUser!.profileImageUrl.isNotEmpty
                    ? NetworkImage(widget.postUser!.profileImageUrl)
                    : null,
                child: widget.postUser?.profileImageUrl == null ||
                        widget.postUser!.profileImageUrl.isEmpty
                    ? Text(_currentPost.userName.isNotEmpty
                        ? _currentPost.userName[0].toUpperCase()
                        : '?')
                    : null,
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(uid: _currentPost.userId),
                    ),
                  );
                },
                child: Text(_currentPost.userName),
              ),
              subtitle: Text(_formatTimestamp(_currentPost.timestamp)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(uid: _currentPost.userId),
                  ),
                );
              },
              trailing: widget.onDeletePressed != null
                  ? IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: showOptions,
                    )
                  : null,
            ),
            // Post görseli
            if (_currentPost.imageUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 300,
                child: kIsWeb
                    ? Image.network(
                        // Firebase Storage direct download URL beklenir
                        _currentPost.imageUrl,
                        fit: BoxFit.cover,
                        headers: const {
                          // Bazı ortamlarda CORS preflight'i tetiklememek için basit GET
                          'accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
                        },
                        errorBuilder: (_, __, ___) => const Icon(Icons.error),
                      )
                    : CachedNetworkImage(
                        imageUrl: _currentPost.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
              ),
            // Beğeni ve yorum butonları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text('${_currentPost.likes.length}'),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.comment),
                    onPressed: _openComments,
                  ),
                  Text('${_currentPost.commentCount}'),
                ],
              ),
            ),
            // Post metni
            if (_currentPost.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(_currentPost.text),
              ),
          ],
        ),
      ),
    );
  }
}