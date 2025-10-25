// employee_models.dart (or auth_models.dart)

class ReportingManagerModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  const ReportingManagerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory ReportingManagerModel.fromJson(Map<String, dynamic> json) {
    return ReportingManagerModel(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
    };
  }
}

class DepartmentModel {
  final int id;
  final String name;

  const DepartmentModel({required this.id, required this.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class DesignationModel {
  final int id;
  final String name;

  const DesignationModel({required this.id, required this.name});

  factory DesignationModel.fromJson(Map<String, dynamic> json) {
    return DesignationModel(id: json['id'] ?? 0, name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
