import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/components/my_text_field.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileUser user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  PlatformFile? imagePickedFile;
  Uint8List? webImage;
  final bioTextController = TextEditingController();

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

  void updateProfile() async {
    final profileCubit = context.read<ProfileCubit>();
    final String uid = widget.user.uid;
    final String? newBio = bioTextController.text.isNotEmpty
        ? bioTextController.text
        : null;
    final imageMobilePath = kIsWeb ? null : imagePickedFile?.path;
    final imageWebBuytes = kIsWeb ? imagePickedFile?.bytes : null;

    if (imagePickedFile != null || newBio != null) {
      profileCubit.updateProfile(
        uid: uid,
        newBio: newBio,
        imageMobilePath: imageMobilePath,
        imageWebBytes: imageWebBuytes,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Text("Güncelleniyor..."),
                ],
              ),
            ),
          );
        } else {
          return buildEditPage();
        }
      },
      listener: (context, state) {
        if (state is ProfileLoaded) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget buildEditPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profili düzenle"),
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(onPressed: updateProfile, icon: Icon(Icons.upload)),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.hardEdge,

              child: (!kIsWeb && imagePickedFile != null)
                  ? Image.file(File(imagePickedFile!.path!), fit: BoxFit.cover)
                  : (kIsWeb && webImage != null)
                  ? Image.memory(webImage!)
                  : widget.user.profileImageUrl.isNotEmpty
                      ? Image.network(
                          widget.user.profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return CircularProgressIndicator();
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 72,
                          color: Theme.of(context).colorScheme.primary,
                        ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: MaterialButton(
              onPressed: pickImage,
              color: Colors.blueAccent,
              child: Text("Resim Seç"),
            ),
          ),
          Text("Bio"),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: MyTextField(
              controller: bioTextController,
              hintText: widget.user.bio,
              obscureText: false,
            ),
          ),
        ],
      ),
    );
  }
}
