import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/home/presentation/components/my_drawer.dart';
import 'package:social/features/home/presentation/components/post_tile.dart';
import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:social/features/posts/presentation/pages/upload_post_page.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Keep last successful posts to avoid empty UI on non-post states (e.g., CommentsLoaded)
  List<Post> _cachedPosts = [];
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında postları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostCubit>().fetcjAllPosts();
    });
  }

  // Post silme işlemi
  void deletePost(Post post) async {
    final authCubit = context.read<AuthCubit>();
    final currentUser = authCubit.currentUser;

    // Sadece kendi postlarını silebilir
    if (currentUser?.uid == post.userId) {
      final postCubit = context.read<PostCubit>();
      await postCubit.deletePost(post.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ana Sayfa"),
        actions: [
          // Yeni post oluşturma sayfasına git
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadPostPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: MyDrawer(),
      body: BlocConsumer<PostCubit, PostStates>(
        listener: (context, state) {
          if (state is PostsLoaded) {
            _cachedPosts = state.posts;
          } else if (state is PostsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          // Stabilizasyon: Cache boşken ve state PostsLoaded değilse güvenli refresh yap
          if (_cachedPosts.isEmpty) {
            if (state is PostsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is! PostsLoaded) {
              // başka bir state (CommentsLoaded vb.) geldi; postları yeniden çek
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // yeniden tetikleme
                context.read<PostCubit>().fetcjAllPosts();
              });
              return const Center(child: CircularProgressIndicator());
            }
          }

          final posts = _cachedPosts;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PostCubit>().fetcjAllPosts();
            },
            child: posts.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text("Henüz gönderi yok")),
                    ],
                  )
                : ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return BlocBuilder<ProfileCubit, ProfileStates>(
                        builder: (context, profileState) {
                          final postUser = profileState is ProfileLoaded &&
                                  profileState.profileUser.uid == post.userId
                              ? profileState.profileUser
                              : null;
                          return PostTile(
                            post: post,
                            postUser: postUser,
                            onDeletePressed:
                                context.read<AuthCubit>().currentUser?.uid ==
                                        post.userId
                                    ? () => deletePost(post)
                                    : null,
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}