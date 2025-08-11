import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social/features/auth/domain/entities/app_user.dart';
import 'package:social/features/auth/presentation/components/my_text_field.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  PlatformFile? imagePickedFile;
  Uint8List? webImage;
  final textController = TextEditingController();
  AppUser? currenUser;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    final authCubit = context.read<AuthCubit>();
    currenUser = authCubit.currentUser;
  }

  Future<void> pickImage() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf seçmek için izin gerekli!')),
          );
          return;
        }
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
      );
      if (result != null) {
        setState(() {
          imagePickedFile = result.files.first;
          if (kIsWeb) {
            webImage = imagePickedFile!.bytes;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Resim seçerken hata oluştu: $e')));
    }
  }

  void uploadPost() {
    if (imagePickedFile == null || textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen hem resim hem yazı ekleyiniz!")),
      );
      return;
    }
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currenUser!.uid,
      userName: currenUser!.name,
      text: textController.text,
      imageUrl: '',
      timestamp: DateTime.now(),
    );
    final postCubit = context.read<PostCubit>();

    if (kIsWeb) {
      postCubit.createPost(newPost, imageBytes: imagePickedFile?.bytes);
    } else {
      postCubit.createPost(newPost, imagePath: imagePickedFile?.path);
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCubit, PostStates>(
      builder: (context, state) {
        if (state is PostsLoading || state is PostsUploading) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return buildUploadPage();
      },
      listener: (context, state) {
        if (state is PostsLoaded) {
          Navigator.pop(context);
        }
        if (state is PostsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
    );
  }

  Widget buildUploadPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gönderi Oluştur"),
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          //upload butonu
          IconButton(onPressed: uploadPost, icon: Icon(Icons.upload)),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            if (kIsWeb && webImage != null) Image.memory(webImage!),
            if (!kIsWeb &&
                imagePickedFile != null &&
                imagePickedFile!.path != null)
              Image.file(File(imagePickedFile!.path!)),

            //pick image button
            MaterialButton(
              onPressed: pickImage,
              color: Colors.blue,
              child: Text("Resim Seç"),
            ),
            // açıklama
            MyTextField(
              controller: textController,
              hintText: "Açıklama",
              obscureText: false,
            ),
          ],
        ),
      ),
    );
  }
}
