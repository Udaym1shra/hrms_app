// Authentication related models based on the existing HRMS API structure

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class User {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? mobile;
  final String workStatus;
  final int? tenantId;
  final int? branchId;
  final int? employeeId;
  final Role? role;
  final Tenant? tenant;
  final Branch? branch;
  final Employee? employee;

  User({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.mobile,
    required this.workStatus,
    this.tenantId,
    this.branchId,
    this.employeeId,
    this.role,
    this.tenant,
    this.branch,
    this.employee,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      workStatus: json['workStatus'] ?? '',
      tenantId: json['tenantId'],
      branchId: json['branchId'],
      employeeId: json['employeeId'],
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      tenant: json['tenantId'] != null ? Tenant.fromJson(json['tenantId']) : null,
      branch: json['branchId'] != null ? Branch.fromJson(json['branchId']) : null,
      employee: json['employee'] != null ? Employee.fromJson(json['employee']) : null,
    );
  }

  String get fullName {
    final parts = [firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    parts.add(lastName);
    return parts.join(' ');
  }
}

class Role {
  final int id;
  final String name;
  final String? description;

  Role({
    required this.id,
    required this.name,
    this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class Tenant {
  final int id;
  final String name;
  final String? description;

  Tenant({
    required this.id,
    required this.name,
    this.description,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class Branch {
  final int id;
  final String name;
  final String? address;
  final int? tenantId;

  Branch({
    required this.id,
    required this.name,
    this.address,
    this.tenantId,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      tenantId: json['tenantId'],
    );
  }
}

class Employee {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String empCode;
  final String? designation;
  final String? department;
  final String? photoPath;

  Employee({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.empCode,
    this.designation,
    this.department,
    this.photoPath,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      empCode: json['empCode'] ?? '',
      designation: json['designation'],
      department: json['department'],
      photoPath: json['photoPath'],
    );
  }

  String get fullName {
    final parts = [firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    parts.add(lastName);
    return parts.join(' ');
  }
}

class LoginResponse {
  final int code;
  final bool error;
  final String message;
  final LoginContent? content;

  LoginResponse({
    required this.code,
    required this.error,
    required this.message,
    this.content,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      code: json['code'] ?? 0,
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      content: json['content'] != null ? LoginContent.fromJson(json['content']) : null,
    );
  }
}

class LoginContent {
  final String token;
  final User user;
  final List<dynamic>? subscriptions;

  LoginContent({
    required this.token,
    required this.user,
    this.subscriptions,
  });

  factory LoginContent.fromJson(Map<String, dynamic> json) {
    return LoginContent(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
      subscriptions: json['subscriptions'],
    );
  }
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final User? user;
  final String? token;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.token,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    User? user,
    String? token,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }
}
