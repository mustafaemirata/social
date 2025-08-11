import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/domain/entities/comment.dart';

abstract class PostRepo {
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId);
  Future<List<Post>> fetchPostsByUserId(String userId);
  
  // Beğeni işlemleri
  Future<void> likePost(String postId, String userId);
  Future<void> unlikePost(String postId, String userId);
  
  // Yorum işlemleri
  Future<void> addComment(Comment comment);
  Future<void> deleteComment(String postId, String commentId);
  Future<List<Comment>> getComments(String postId);
  Future<void> updateCommentCount(String postId, int count);
}