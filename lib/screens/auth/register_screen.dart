import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/cloudinary_service.dart';
import 'dart:developer' as developer;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _qrcodeController = TextEditingController();
  
  File? _avatarImage;
  File? _qrcodeImage;
  final _cloudinaryService = CloudinaryService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      developer.log('Bắt đầu chọn ảnh loại: $type', name: 'RegisterScreen');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        developer.log('Đã chọn ảnh thành công: ${image.path}', name: 'RegisterScreen');
        setState(() {
          switch (type) {
            case 'avatar':
              _avatarImage = File(image.path);
              break;
            case 'qrcode':
              _qrcodeImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      developer.log('Lỗi khi chọn ảnh: ${e.toString()}', name: 'RegisterScreen', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage(File? image) async {
    if (image == null) return null;
    try {
      developer.log('Bắt đầu upload ảnh: ${image.path}', name: 'RegisterScreen');
      final url = await _cloudinaryService.uploadImageFromPath(
        path: image.path,
        imageQuality: 0.6,
      );
      developer.log('Upload ảnh thành công: $url', name: 'RegisterScreen');
      return url;
    } catch (e) {
      developer.log('Lỗi khi upload ảnh: ${e.toString()}', name: 'RegisterScreen', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải ảnh lên: ${e.toString()}')),
      );
      return null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _qrcodeController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker(String type, File? image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type == 'avatar' ? 'Ảnh đại diện' :
          type == 'qrcode' ? 'Mã QR' : '',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery, type),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.add_photo_alternate, size: 50),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            developer.log('Lỗi xác thực: ${state.message}', name: 'RegisterScreen', error: state.message);
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is Authenticated) {
            developer.log('Đăng ký thành công, chuyển về màn hình trước', name: 'RegisterScreen');
            Navigator.pop(context);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagePicker('avatar', _avatarImage),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ tên',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập địa chỉ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildImagePicker('qrcode', _qrcodeImage),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  developer.log('Bắt đầu xử lý đăng ký', name: 'RegisterScreen');
                                  if (_formKey.currentState!.validate()) {
                                    developer.log('Form hợp lệ, bắt đầu upload ảnh', name: 'RegisterScreen');
                                    setState(() => _isLoading = true);
                                    
                                    final avatarUrl = await _uploadImage(_avatarImage);
                                    final qrcodeUrl = await _uploadImage(_qrcodeImage);

                                    if (avatarUrl == null || qrcodeUrl == null) {
                                      developer.log('Upload ảnh thất bại', name: 'RegisterScreen');
                                      setState(() => _isLoading = false);
                                      return;
                                    }

                                    developer.log('Upload ảnh thành công, bắt đầu tạo tài khoản', name: 'RegisterScreen');
                                    developer.log('Thông tin đăng ký: Email: ${_emailController.text}, Name: ${_nameController.text}, Phone: ${_phoneController.text}', name: 'RegisterScreen');

                                    context.read<AuthBloc>().add(
                                          SignUpEvent(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                            name: _nameController.text,
                                            phone: _phoneController.text,
                                            address: _addressController.text,
                                            avatar: avatarUrl,
                                            qrcode: qrcodeUrl,
                                          ),
                                        );
                                  } else {
                                    developer.log('Form không hợp lệ', name: 'RegisterScreen');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Đăng ký',
                                  style: TextStyle(fontSize: 16),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 