import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/home/presentation/components/my_drawer_tile.dart';
import 'package:social/features/profile/presentation/pages/profile_page.dart';
import 'package:social/features/search/presentation/pages/search_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: .0),
          child: Column(
            children: [
              //logo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Icon(
                  Icons.person,
                  size: 70,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              //divider line
              Divider(color: Theme.of(context).colorScheme.secondary),

              //home tile
              MyDrawerTile(
                title: "H O M E",
                icon: Icons.home,
                onTap: () => Navigator.of(context).pop(),
              ),
              

              //profile
              MyDrawerTile(
                title: "P R O F I L E",
                icon: Icons.person,
                onTap: () {
                  Navigator.of(context).pop();

                  //get current userid
                   final user=context.read<AuthCubit>().currentUser;
                   String? uid=user!.uid;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage(uid:uid)),
                  );
                },
              ),

              //search
              MyDrawerTile(
                title: "S E A R C H",
                icon: Icons.search,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchPage()),
                  );
                },
              ),

              //settings
              MyDrawerTile(
                title: "S E T T I N G S",
                icon: Icons.settings,
                onTap: () {},
              ),
              Spacer(),

              //logout
              MyDrawerTile(
                title: "L O G  O U T",
                icon: Icons.logout,
                onTap: () =>context.read<AuthCubit>().logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}