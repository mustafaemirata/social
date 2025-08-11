import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/data/firebase_auth_repo.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/auth/presentation/cubits/auth_states.dart';
import 'package:social/features/auth/presentation/pages/auth_page.dart';
import 'package:social/features/home/presentation/pages/home_page.dart';
import 'package:social/features/posts/data/firebase_repository.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/profile/data/firebase_profile_repo.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/storage/data/firebase_storage_repo.dart';
import 'package:social/themes/light_mode.dart';

class MyApp extends StatelessWidget {
  //auth repo

  final firebaseAuthRepo = FirebaseAuthRepo();

  //profile repo
  final firebaseProfileRepo = FirebaseProfileRepo();

  //storage repo
  final firebaseStorageRepo = FirebaseStorageRepo();

  //post repo
  final firebasePostRepo = FirebaseRepository();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //provide app
    return MultiBlocProvider(
      providers: [
        //auth cubit
        BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepo: firebaseAuthRepo)..checkAuth(),
        ),

        //profile cubit
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            profileRepo: firebaseProfileRepo,
            storageRepo: firebaseStorageRepo,
          ),
        ),

        //post cubit
        BlocProvider<PostCubit>(
          create: (context) => PostCubit(
            postRepo: firebasePostRepo,
            storageRepo: firebaseStorageRepo,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightMode,
        home: BlocConsumer<AuthCubit, AuthStates>(
          builder: (context, authState) {
            print(authState);
            //unauthenticated
            if (authState is UnAuthenticated) {
              return AuthPage();
            }

            if (authState is Authenticated) {
              return HomePage();
            }
            // loading
            else {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            }
          },
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ),
    );
  }
}
