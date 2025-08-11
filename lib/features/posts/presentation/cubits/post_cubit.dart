import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/domain/entities/comment.dart';
import 'package:social/features/posts/domain/repos/post_repo.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:social/features/storage/domain/storage_repo.dart';

class PostCubit extends Cubit<PostStates> {
  final PostRepo postRepo;
  final StorageRepo storageRepo;
  List<Post> _currentPosts = [];
  Map<String, List<Comment>> _commentsCache = {};

  PostCubit({required this.postRepo, required this.storageRepo})
      : super(PostsInitial());

  // Tüm postları getir
  Future<void> fetcjAllPosts() async {
    try {
      emit(PostsLoading());
      final posts = await postRepo.fetchAllPosts();
      _currentPosts = posts;
      emit(PostsLoaded(posts));
    } catch (e) {
      emit(PostsError("Gönderiler yüklenemedi: $e"));
    }
  }

  // Kullanıcının postlarını getir
  Future<void> fetchUserPosts(String userId) async {
    try {
      emit(PostsLoading());
      final posts = await postRepo.fetchPostsByUserId(userId);
      emit(PostsLoaded(posts));
    } catch (e) {
      emit(PostsError("Kullanıcı gönderileri yüklenemedi: $e"));
    }
  }

  // Yeni gönderi oluşturma
  Future<void> createPost(
    Post post, {
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    String? imageUrl;

    try {
      emit(PostsUploading());
      if (imagePath != null) {
        imageUrl = await storageRepo.uploadPostImageMobile(
          imagePath,
          post.id,
        );
      } else if (imageBytes != null) {
        imageUrl = await storageRepo.uploadPostImageWeb(
          imageBytes,
          post.id,
        );
      }

      if (imageUrl == null) {
        emit(PostsError("Görsel yüklenemedi!"));
        return;
      }

      final newPost = post.copyWith(imageUrl: imageUrl);
      await postRepo.createPost(newPost);
      await fetcjAllPosts();
    } catch (e) {
      emit(PostsError("Gönderi oluşturulamadı: $e"));
    }
  }

  // Post silme
  Future<void> deletePost(String postId) async {
    try {
      await postRepo.deletePost(postId);
      _currentPosts.removeWhere((post) => post.id == postId);
      emit(PostsLoaded(_currentPosts));
    } catch (e) {
      emit(PostsError("Gönderi silinemedi: $e"));
    }
  }

  // Post beğenme
  Future<void> likePost(String postId, String userId) async {
    try {
      await postRepo.likePost(postId, userId);
      final updatedPosts = _currentPosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(likes: [...post.likes, userId]);
        }
        return post;
      }).toList();
      _currentPosts = updatedPosts;
      emit(PostsLoaded(updatedPosts));
    } catch (e) {
      emit(PostsError("Gönderi beğenilemedi: $e"));
    }
  }

  // Beğeniyi kaldırma
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await postRepo.unlikePost(postId, userId);
      final updatedPosts = _currentPosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            likes: post.likes.where((id) => id != userId).toList(),
          );
        }
        return post;
      }).toList();
      _currentPosts = updatedPosts;
      emit(PostsLoaded(updatedPosts));
    } catch (e) {
      emit(PostsError("Beğeni kaldırılamadı: $e"));
    }
  }

  // Yorum ekleme
  Future<void> addComment(Comment comment) async {
    // Optimistic update
    final currentComments = List<Comment>.from(_commentsCache[comment.postId] ?? []);
    final currentPostsSnapshot = List<Post>.from(_currentPosts);
    try {
      // Önce local güncelle
      _commentsCache[comment.postId] = [comment, ...currentComments];
      _currentPosts = _currentPosts.map((post) {
        if (post.id == comment.postId) {
          return post.copyWith(commentCount: post.commentCount + 1);
        }
        return post;
      }).toList();
      emit(PostsLoaded(_currentPosts));
      emit(CommentsLoaded(_commentsCache[comment.postId]!));

      // Sonra sunucuya yaz
      await postRepo.addComment(comment);
    } catch (e) {
      // Geri al
      _commentsCache[comment.postId] = currentComments;
      _currentPosts = currentPostsSnapshot;
      emit(PostsLoaded(_currentPosts));
      emit(CommentsLoaded(_commentsCache[comment.postId] ?? []));
      emit(PostsError("Yorum eklenemedi: $e"));
    }
  }

  // Yorumları getir
  Future<void> getComments(String postId) async {
    try {
      emit(CommentsLoading());
      final comments = await postRepo.getComments(postId);
      _commentsCache[postId] = comments;
      emit(CommentsLoaded(comments));
    } catch (e) {
      emit(PostsError("Yorumlar yüklenemedi: $e"));
    }
  }

  // Yorum silme
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await postRepo.deleteComment(postId, commentId);
      
      // Yorum cache'ini güncelle
      _commentsCache[postId]?.removeWhere((comment) => comment.id == commentId);
      
      // Post'un yorum sayısını güncelle
      final updatedPosts = _currentPosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentCount: post.commentCount - 1);
        }
        return post;
      }).toList();
      _currentPosts = updatedPosts;

      emit(PostsLoaded(updatedPosts));
      emit(CommentsLoaded(_commentsCache[postId]!));
    } catch (e) {
      emit(PostsError("Yorum silinemedi: $e"));
    }
  }
}