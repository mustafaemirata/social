import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/posts/domain/entities/comment.dart';
import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:intl/intl.dart';
import 'package:social/features/profile/presentation/pages/profile_page.dart';

class CommentsPage extends StatefulWidget {
  final Post post;
  
  const CommentsPage({
    super.key,
    required this.post,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadComments() {
    setState(() {
      _isLoadingComments = true;
    });
    context.read<PostCubit>().getComments(widget.post.id);
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

  void _addComment() async {
    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null || _commentController.text.trim().isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.post.id,
      userId: currentUser.uid,
      userName: currentUser.name,
      userProfileImageUrl: currentUser.profileImageUrl ?? '',
      text: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    // Yorumu optimistic olarak ekle
    setState(() {
      _comments.insert(0, comment);
    });

    try {
      await context.read<PostCubit>().addComment(comment);
      _commentController.clear();
    } catch (e) {
      // Hata durumunda yorumu kaldır
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum eklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yorumlar"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: BlocListener<PostCubit, PostStates>(
        listener: (context, state) {
          if (state is CommentsLoaded) {
            setState(() {
              _comments = state.comments;
              _isLoadingComments = false;
            });
          } else if (state is CommentsLoading) {
            setState(() {
              _isLoadingComments = true;
            });
          } else if (state is PostsError) {
            setState(() {
              _isLoadingComments = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Yorumlar yüklenirken hata oluştu'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Post önizlemesi
            Card(
              margin: EdgeInsets.all(8.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfilePage(uid: widget.post.userId),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            child: Text(
                              widget.post.userName.isNotEmpty
                                  ? widget.post.userName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfilePage(uid: widget.post.userId),
                                    ),
                                  );
                                },
                                child: Text(
                                  widget.post.userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTimestamp(widget.post.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.post.text.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Text(widget.post.text),
                    ],
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red, size: 16),
                        SizedBox(width: 4),
                        Text('${widget.post.likes.length}'),
                        SizedBox(width: 16),
                        Icon(Icons.comment, size: 16),
                        SizedBox(width: 4),
                        Text('${widget.post.commentCount}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(),
            // Yorum yazma alanı
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Builder(builder: (context) {
                    final currentName =
                        (context.read<AuthCubit>().currentUser?.name ?? '').trim();
                    final initial =
                        currentName.isNotEmpty ? currentName[0].toUpperCase() : '?';
                    return CircleAvatar(
                      radius: 20,
                      child: Text(initial),
                    );
                  }),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  SizedBox(width: 8),
                  _isAddingComment
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: _addComment,
                        ),
                ],
              ),
            ),
            // Yorumlar listesi
            Expanded(
              child: _isLoadingComments
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Henüz yorum yok',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'İlk yorumu sen yap!',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            _loadComments();
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: comment.userProfileImageUrl.isNotEmpty
                                          ? (kIsWeb
                                              ? NetworkImage(comment.userProfileImageUrl)
                                              : CachedNetworkImageProvider(comment.userProfileImageUrl)
                                                  as ImageProvider)
                                          : null,
                                      child: comment.userProfileImageUrl.isEmpty
                                          ? Text(
                                              comment.userName.isNotEmpty
                                                  ? comment.userName[0].toUpperCase()
                                                  : '?',
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => ProfilePage(uid: comment.userId),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    comment.userName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  comment.text,
                                                  style: TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Padding(
                                            padding: EdgeInsets.only(left: 16),
                                            child: Text(
                                              _formatTimestamp(comment.timestamp),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
