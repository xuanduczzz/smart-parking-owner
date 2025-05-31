import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_state.dart';
import '../blocs/profile/profile_event.dart';
import '../models/owner_model.dart';
import '../screens/auth/login_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    // Load profile khi drawer được mở
    if (user != null) {
      context.read<ProfileBloc>().add(LoadProfileEvent(user.uid));
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              String displayName = 'Chưa cập nhật tên';
              String? avatarUrl;
              
              if (state is ProfileLoaded || state is ProfileUpdated) {
                final profile = state is ProfileLoaded 
                    ? state.profile 
                    : (state as ProfileUpdated).profile;
                displayName = profile.name;
                avatarUrl = profile.avatar;
              }

              return UserAccountsDrawerHeader(
                accountName: Text(displayName),
                accountEmail: Text(user?.email ?? 'Chưa cập nhật email'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          _getInitials(displayName),
                          style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                        )
                      : null,
                ),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Thông tin cá nhân'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Cài đặt'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context); // Đóng drawer
                  // Xóa tất cả các màn hình trong stack và chuyển về màn hình login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi đăng xuất: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
} 