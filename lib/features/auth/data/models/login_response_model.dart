import 'user_model.dart';

// Login response model
class LoginResponseModel {
  final int code;
  final bool error;
  final String message;
  final LoginContentModel? content;

  const LoginResponseModel({
    required this.code,
    required this.error,
    required this.message,
    this.content,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      code: json['code'] ?? 0,
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      content: json['content'] != null ? LoginContentModel.fromJson(json['content']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'error': error,
      'message': message,
      'content': content?.toJson(),
    };
  }
}

class LoginContentModel {
  final String token;
  final UserModel user;
  final List<dynamic>? subscriptions;

  const LoginContentModel({
    required this.token,
    required this.user,
    this.subscriptions,
  });

  factory LoginContentModel.fromJson(Map<String, dynamic> json) {
    return LoginContentModel(
      token: json['token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      subscriptions: json['subscriptions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'subscriptions': subscriptions,
    };
  }
}
