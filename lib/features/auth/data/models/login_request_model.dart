// Login request model
class LoginRequestModel {
  final String email;
  final String password;

  const LoginRequestModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) {
    return LoginRequestModel(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }

  // Validation methods
  bool isValid() {
    return email.isNotEmpty && 
           password.isNotEmpty && 
           _isValidEmail(email) && 
           _isValidPassword(password);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6 && password.length <= 50;
  }

  String? getValidationError() {
    if (email.isEmpty) return 'Email is required';
    if (!_isValidEmail(email)) return 'Please enter a valid email';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    if (password.length > 50) return 'Password must be less than 50 characters';
    return null;
  }
}
