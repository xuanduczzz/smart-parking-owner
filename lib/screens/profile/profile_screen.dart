import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import '../../models/owner_model.dart';
import '../../services/cloudinary_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  final _cloudinaryService = CloudinaryService();
  String? _tempAvatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      context.read<ProfileBloc>().add(LoadProfileEvent(userId));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final imageUrl = await _cloudinaryService.uploadImage(
        source: ImageSource.gallery,
        maxWidth: 400.0,
        maxHeight: 400.0,
        imageQuality: 0.6,
      );

      if (imageUrl != null) {
        setState(() {
          _tempAvatarUrl = imageUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _pickAndUploadQRCode() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final imageUrl = await _cloudinaryService.uploadImage(
        source: ImageSource.gallery,
        maxWidth: 400.0,
        maxHeight: 400.0,
        imageQuality: 0.6,
      );

      if (imageUrl != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          context.read<ProfileBloc>().add(
            UpdateQRCodeEvent(
              userId: userId,
              qrCodeUrl: imageUrl,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh QR: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        if (_tempAvatarUrl != null) {
          context.read<ProfileBloc>().add(
            UpdateAvatarEvent(
              userId: userId,
              avatarUrl: _tempAvatarUrl!,
            ),
          );
        }
        
        context.read<ProfileBloc>().add(
          UpdateProfileEvent(
            userId: userId,
            name: _nameController.text,
            phone: _phoneController.text,
            address: _addressController.text,
          ),
        );
      }
    }
  }

  Widget _buildProfileForm(OwnerModel profile) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar Section
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.cardColor,
                        backgroundImage: (_tempAvatarUrl ?? profile.avatar).isNotEmpty
                            ? NetworkImage(_tempAvatarUrl ?? profile.avatar)
                            : null,
                        child: (_tempAvatarUrl ?? profile.avatar).isEmpty
                            ? Text(
                                profile.name.substring(0, 1).toUpperCase(),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (_isUploading)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isUploading ? 'Đang tải ảnh...' : 'Nhấn để thay đổi ảnh',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 32),
              // Form Fields
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Email (read-only)
                    TextFormField(
                      initialValue: profile.email,
                      enabled: false,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: tr('email'),
                        labelStyle: theme.textTheme.bodyMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    TextFormField(
                      controller: _nameController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: tr('name'),
                        labelStyle: theme.textTheme.bodyMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: tr('phone'),
                        labelStyle: theme.textTheme.bodyMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address
                    TextFormField(
                      controller: _addressController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: tr('address'),
                        labelStyle: theme.textTheme.bodyMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                        prefixIcon: Icon(Icons.location_on, color: theme.colorScheme.primary),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập địa chỉ';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // QR Code Section
              if (profile.qrcode.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Mã QR của bạn',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                profile.qrcode,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _isUploading ? null : _pickAndUploadQRCode,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isUploading ? 'Đang tải ảnh...' : 'Nhấn để thay đổi mã QR',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Cập nhật',
                    style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('profile'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _nameController.text = state.profile.name;
            _phoneController.text = state.profile.phone;
            _addressController.text = state.profile.address;
            setState(() {
              _tempAvatarUrl = null;
            });
          } else if (state is ProfileUpdated) {
            _nameController.text = state.profile.name;
            _phoneController.text = state.profile.phone;
            _addressController.text = state.profile.address;
            setState(() {
              _tempAvatarUrl = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cập nhật thông tin thành công',
                  style: theme.textTheme.bodyMedium,
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: theme.textTheme.bodyMedium,
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileUpdating) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ProfileLoaded || state is ProfileUpdated) {
            final profile = state is ProfileLoaded 
                ? state.profile 
                : (state as ProfileUpdated).profile;
            return _buildProfileForm(profile);
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        context.read<ProfileBloc>().add(LoadProfileEvent(userId));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Thử lại',
                      style: theme.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Text(
              'Không thể tải thông tin',
              style: theme.textTheme.bodyMedium,
            ),
          );
        },
      ),
    );
  }
} 