import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

// F17 / FR-AUTH-05: sua ho so - ho ten (bat buoc), so dien thoai, anh dai dien JPG/PNG <= 2 MB.
// Form + TextFormField + validator (Module 7).
const maxAvatarBytes = 2 * 1024 * 1024;

String? validateFullName(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Vui lòng nhập họ tên';
  if (v.length < 2) return 'Họ tên tối thiểu 2 ký tự';
  if (v.length > 100) return 'Họ tên tối đa 100 ký tự';
  return null;
}

String? validatePhone(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null; // khong bat buoc
  if (!RegExp(r'^(0|\+84)\d{9}$').hasMatch(v)) return 'Số điện thoại gồm 10 số, bắt đầu bằng 0 hoặc +84';
  return null;
}

// Nhan dien JPG / PNG theo noi dung file (magic bytes), khong tin ten file: tren Android ten tu bo chon anh co the rong
String? imageMime(Uint8List bytes) {
  if (bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return 'image/png';
  if (bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return 'image/jpeg';
  return null;
}

// Tra ve loi neu anh khong hop le; null neu dung dinh dang va dung luong
String? validateAvatar(Uint8List bytes) {
  if (imageMime(bytes) == null) return 'Ảnh đại diện chỉ nhận JPG hoặc PNG';
  if (bytes.length > maxAvatarBytes) return 'Ảnh đại diện tối đa 2 MB';
  return null;
}

// Hien anh dai dien tu data URL (base64) luu tren may chu
ImageProvider? avatarImage(String? avatar) {
  if (avatar == null || !avatar.startsWith('data:image/')) return null;
  try {
    return MemoryImage(base64Decode(avatar.substring(avatar.indexOf(',') + 1)));
  } catch (_) {
    return null;
  }
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, this.picker});

  // Cho phep test thay bo chon anh
  final Future<XFile?> Function()? picker;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  String? _avatar; // data URL moi chon (chua luu)
  String? _avatarError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final pick = widget.picker ??
        () => ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    final file = await pick();
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    final error = validateAvatar(bytes);
    setState(() {
      _avatarError = error;
      if (error == null) {
        _avatar = 'data:${imageMime(bytes)};base64,${base64Encode(bytes)}';
      }
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _avatarError != null) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    try {
      final user = await context.read<ProfileService>().update(
            fullName: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            avatar: _avatar,
          );
      await auth.updateUser(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final image = avatarImage(_avatar ?? user?.avatar);
    return Scaffold(
      appBar: AppBar(title: const Text('Sửa hồ sơ')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primarySoft,
                    foregroundImage: image,
                    child: const Icon(Icons.person, size: 48, color: AppColors.primaryDark),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      key: const Key('pick-avatar'),
                      tooltip: 'Chọn ảnh đại diện',
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _avatarError ?? 'Ảnh JPG hoặc PNG, tối đa 2 MB',
              textAlign: TextAlign.center,
              style: TextStyle(color: _avatarError == null ? AppColors.textSecondary : AppColors.danger, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('full-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Họ tên *', prefixIcon: Icon(Icons.badge_outlined)),
              validator: validateFullName,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined)),
              validator: validatePhone,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: user?.email ?? '',
              enabled: false,
              decoration: const InputDecoration(labelText: 'Email (không đổi được)', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('save-profile'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}
