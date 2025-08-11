import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/domain/entities/comment.dart';
import 'package:social/features/posts/domain/repos/post_repo.dart';

class FirebaseRepository implements PostRepo {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  // collection "posts"
  final CollectionReference postCollection =
      FirebaseFirestore.instance.collection('posts');

  @override
  Future<void> createPost(Post post) async {
    try {
      await postCollection.doc(post.id).set(post.toJson());
    } catch (e) {
      throw Exception("Gönderi oluşturma hatası: $e");
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      // Önce postun yorumlarını sil
      final commentsCollection = postCollection.doc(postId).collection('comments');
      final commentsSnapshot = await commentsCollection.get();
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      // Sonra postu sil
      await postCollection.doc(postId).delete();
    } catch (e) {
      throw Exception("Gönderi silme hatası: $e");
    }
  }

  @override
  Future<List<Post>> fetchAllPosts() async {
    try {
      final postsSnapshot = await postCollection
          .orderBy('timestamp', descending: true)
          .get();

      final List<Post> allPosts = postsSnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return allPosts;
    } catch (e) {
      throw Exception("Gönderiler alınırken hata oluştu: $e");
    }
  }

  @override
  Future<List<Post>> fetchPostsByUserId(String userId) async {
    try {
      final postsSnapshot =
          await postCollection.where('userId', isEqualTo: userId).get();

      final userPosts = postsSnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return userPosts;
    } catch (e) {
      throw Exception("Kullanıcı gönderileri alınırken hata oluştu: $e");
    }
  }

  @override
  Future<void> likePost(String postId, String userId) async {
    try {
      await postCollection.doc(postId).update({
        'likes': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw Exception("Beğeni eklenirken hata oluştu: $e");
    }
  }

  @override
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await postCollection.doc(postId).update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw Exception("Beğeni kaldırılırken hata oluştu: $e");
    }
  }

  @override
  Future<void> addComment(Comment comment) async {
    try {
      final postRef = postCollection.doc(comment.postId);
      final commentsRef = postRef.collection('comments').doc(comment.id);

      await FirebaseFirestore.instance.runTransaction((txn) async {
        // Yorumu yaz
        txn.set(commentsRef, comment.toJson());
        // Post üzerindeki commentCount'u atomik artır
        txn.update(postRef, {
          'commentCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception("Yorum eklenirken hata oluştu: $e");
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final postRef = postCollection.doc(postId);
      final commentRef = postRef.collection('comments').doc(commentId);

      await FirebaseFirestore.instance.runTransaction((txn) async {
        txn.delete(commentRef);
        txn.update(postRef, {
          'commentCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception("Yorum silinirken hata oluştu: $e");
    }
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    try {
      final commentsSnapshot = await postCollection
          .doc(postId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      return commentsSnapshot.docs
          .map((doc) => Comment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Yorumlar alınırken hata oluştu: $e");
    }
  }

  @override
  Future<void> updateCommentCount(String postId, int count) async {
    try {
      await postCollection.doc(postId).update({'commentCount': count});
    } catch (e) {
      throw Exception("Yorum sayısı güncellenirken hata oluştu: $e");
    }
  }
}