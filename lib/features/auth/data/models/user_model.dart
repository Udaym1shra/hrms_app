// User model for authentication
class UserModel {
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
  final RoleModel? role;
  final TenantModel? tenant;
  final BranchModel? branch;
  final EmployeeModel? employee;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
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
      role: json['role'] != null ? RoleModel.fromJson(json['role']) : null,
      tenant: json['tenant'] != null ? TenantModel.fromJson(json['tenant']) : null,
      branch: json['branch'] != null ? BranchModel.fromJson(json['branch']) : null,
      employee: json['employee'] != null ? EmployeeModel.fromJson(json['employee']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'workStatus': workStatus,
      'tenantId': tenantId,
      'branchId': branchId,
      'employeeId': employeeId,
      'role': role?.toJson(),
      'tenant': tenant?.toJson(),
      'branch': branch?.toJson(),
      'employee': employee?.toJson(),
    };
  }

  String get fullName {
    final parts = [firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    parts.add(lastName);
    return parts.join(' ');
  }

  UserModel copyWith({
    int? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? mobile,
    String? workStatus,
    int? tenantId,
    int? branchId,
    int? employeeId,
    RoleModel? role,
    TenantModel? tenant,
    BranchModel? branch,
    EmployeeModel? employee,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      workStatus: workStatus ?? this.workStatus,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      tenant: tenant ?? this.tenant,
      branch: branch ?? this.branch,
      employee: employee ?? this.employee,
    );
  }
}

class RoleModel {
  final int id;
  final String name;
  final String? description;

  const RoleModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class TenantModel {
  final int id;
  final String name;
  final String? description;

  const TenantModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class BranchModel {
  final int id;
  final String name;
  final String? address;
  final int? tenantId;

  const BranchModel({
    required this.id,
    required this.name,
    this.address,
    this.tenantId,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      tenantId: json['tenantId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'tenantId': tenantId,
    };
  }
}

class EmployeeModel {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String empCode;
  final String? designation;
  final String? department;
  final String? photoPath;

  const EmployeeModel({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.empCode,
    this.designation,
    this.department,
    this.photoPath,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'empCode': empCode,
      'designation': designation,
      'department': department,
      'photoPath': photoPath,
    };
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
