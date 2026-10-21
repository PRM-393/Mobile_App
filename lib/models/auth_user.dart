// Nguoi dung dang nhap (FR-AUTH-07: 5 vai tro, app khach hang chi dung CUSTOMER)
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.avatar,
  });

  final String id;
  final String email;
  final String role;
  final String? fullName;
  final String? phone;
  final String? avatar;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    role: json['role'] as String? ?? 'CUSTOMER',
    fullName: json['fullName'] as String?,
    phone: json['phone'] as String?,
    avatar: json['avatar'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'role': role,
    'fullName': fullName,
    'phone': phone,
    'avatar': avatar,
  };
}

// Phan hoi cua /auth/otp/verify, /auth/login, /auth/refresh
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}
