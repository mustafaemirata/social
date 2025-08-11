import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/domain/entities/comment.dart';

abstract class PostStates {}

class PostsInitial extends PostStates {}

class PostsLoading extends PostStates {}

class PostsUploading extends PostStates {}

class PostsError extends PostStates {
  final String message;
  PostsError(this.message);
}

class PostsLoaded extends PostStates {
  final List<Post> posts;
  PostsLoaded(this.posts);
}

class CommentsLoading extends PostStates {}

class CommentsLoaded extends PostStates {
  final List<Comment> comments;
  CommentsLoaded(this.comments);
}

class CommentAdded extends PostStates {
  final Comment comment;
  CommentAdded(this.comment);
}

class CommentDeleted extends PostStates {
  final String commentId;
  CommentDeleted(this.commentId);
}

class PostLiked extends PostStates {
  final String postId;
  PostLiked(this.postId);
}

class PostUnliked extends PostStates {
  final String postId;
  PostUnliked(this.postId);
}