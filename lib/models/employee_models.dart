// Employee related models based on the existing HRMS API structure

class Employee {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String dob;
  final String gender;
  final String maritalStatus;
  final String bloodGroup;
  final String workStatus;
  final String? confirmationStatus;
  final String empType;
  final String employmentType;
  final String? drivingLicense;
  final String? experienceType;
  final String? religion;
  final double? salary;
  final String email;
  final String? mobile;
  final String? alternateMobile;
  final String? panNumber;
  final String? pfNumber;
  final String? pfUanNumber;
  final String? esiNumber;
  final String? photoPath;
  final String? resumePath;
  final String? personalMark;
  final String? temporaryAddress;
  final String? permanentAddress;
  final String? empSkills;
  final String empCode;
  final String? buildingFloor;
  final int? vendorId;
  final String? aboutEmployee;
  final String? joinDate;
  final String? confirmationDueDate;
  final String? confirmedDate;
  final String? resignationDate;
  final String? leaveDate;
  final String? leaveReason;
  final int? reportingManagerId;
  final int departmentId;
  final int designationId;
  final int companyId;
  final int tenantIds;
  final int branchId;
  final int roleId;
  final String? aadharNumber;
  final String? passportNumber;
  final String? passportExpiry;
  final String? alternateEmail;
  final String? officialEmail;
  final String? nationality;
  final String? referredBy;
  final String? source;
  final String? remarks;
  final String createdAt;
  final String updatedAt;
  final String dateOfBirth;

  // Relations
  final Department? departmentModel;
  final Designation? designationModel;
  final Role? masterRoleModel;
  final Branch? branchModel;
  final Company? companyModel;
  final List<FamilyMember>? familyMembers;
  final List<Education>? educations;
  final List<Experience>? experienceData;
  final BankInformation? bankInformation;
  final List<EmergencyContact>? emergencyContacts;
  final ReportingManager? reportingManager;
  final Manager? manager;

  Employee({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dob,
    required this.gender,
    required this.maritalStatus,
    required this.bloodGroup,
    required this.workStatus,
    this.confirmationStatus,
    required this.empType,
    required this.employmentType,
    this.drivingLicense,
    this.experienceType,
    this.religion,
    this.salary,
    required this.email,
    this.mobile,
    this.alternateMobile,
    this.panNumber,
    this.pfNumber,
    this.pfUanNumber,
    this.esiNumber,
    this.photoPath,
    this.resumePath,
    this.personalMark,
    this.temporaryAddress,
    this.permanentAddress,
    this.empSkills,
    required this.empCode,
    this.buildingFloor,
    this.vendorId,
    this.aboutEmployee,
    this.joinDate,
    this.confirmationDueDate,
    this.confirmedDate,
    this.resignationDate,
    this.leaveDate,
    this.leaveReason,
    this.reportingManagerId,
    required this.departmentId,
    required this.designationId,
    required this.companyId,
    required this.tenantIds,
    required this.branchId,
    required this.roleId,
    this.aadharNumber,
    this.passportNumber,
    this.passportExpiry,
    this.alternateEmail,
    this.officialEmail,
    this.nationality,
    this.referredBy,
    this.source,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.dateOfBirth,
    this.departmentModel,
    this.designationModel,
    this.masterRoleModel,
    this.branchModel,
    this.companyModel,
    this.familyMembers,
    this.educations,
    this.experienceData,
    this.bankInformation,
    this.emergencyContacts,
    this.reportingManager,
    this.manager,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] != null ? json['gender'].toString() : '',
      maritalStatus: json['maritalStatus'] != null
          ? json['maritalStatus'].toString()
          : '',
      bloodGroup: json['bloodGroup'] != null
          ? json['bloodGroup'].toString()
          : '',
      workStatus: json['workStatus'] ?? '',
      confirmationStatus: json['confirmationStatus'],
      empType: json['empType'] ?? '',
      employmentType: json['employmentType'] ?? '',
      drivingLicense: json['drivingLicense'],
      experienceType: json['experienceType'],
      religion: json['religion'] != null ? json['religion'].toString() : null,
      salary: json['salary']?.toDouble(),
      email: json['email'] ?? '',
      mobile: json['mobile'],
      alternateMobile: json['alternateMobile'],
      panNumber: json['panNumber'],
      pfNumber: json['pfNumber'],
      pfUanNumber: json['pfUanNumber'],
      esiNumber: json['esiNumber'],
      photoPath: json['photoPath'],
      resumePath: json['resumePath'],
      personalMark: json['personalMark'],
      temporaryAddress: json['temporaryAddress'],
      permanentAddress: json['permanentAddress'],
      empSkills: json['empSkills'],
      empCode: json['empCode'] ?? '',
      buildingFloor: json['buildingFloor'],
      vendorId: json['vendorId'],
      aboutEmployee: json['aboutEmployee'],
      joinDate: json['joinDate'],
      confirmationDueDate: json['confirmationDueDate'],
      confirmedDate: json['confirmedDate'],
      resignationDate: json['resignationDate'],
      leaveDate: json['leaveDate'],
      leaveReason: json['leaveReason'],
      reportingManagerId: json['reportingManagerId'],
      departmentId: json['departmentId'] ?? 0,
      designationId: json['designationId'] ?? 0,
      companyId: json['companyId'] ?? 0,
      tenantIds: json['tenantIds'] ?? 0,
      branchId: json['branchId'] ?? 0,
      roleId: json['roleId'] ?? 0,
      aadharNumber: json['aadharNumber'],
      passportNumber: json['passportNumber'],
      passportExpiry: json['passportExpiry'],
      alternateEmail: json['alternateEmail'],
      officialEmail: json['officialEmail'],
      nationality: json['nationality'] != null
          ? json['nationality'].toString()
          : null,
      referredBy: json['referredBy'],
      source: json['source'],
      remarks: json['remarks'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      departmentModel: json['DepartmentModel'] != null
          ? Department.fromJson(json['DepartmentModel'])
          : null,
      designationModel: json['DesignationModel'] != null
          ? Designation.fromJson(json['DesignationModel'])
          : null,
      masterRoleModel: json['MasterRoleModel'] != null
          ? Role.fromJson(json['MasterRoleModel'])
          : null,
      branchModel: json['BranchModel'] != null
          ? Branch.fromJson(json['BranchModel'])
          : null,
      companyModel: json['CompanyModel'] != null
          ? Company.fromJson(json['CompanyModel'])
          : null,
      familyMembers: json['familyMembers'] != null
          ? (json['familyMembers'] as List)
                .map((e) => FamilyMember.fromJson(e))
                .toList()
          : null,
      educations: json['educations'] != null
          ? (json['educations'] as List)
                .map((e) => Education.fromJson(e))
                .toList()
          : null,
      experienceData: json['experienceData'] != null
          ? (json['experienceData'] as List)
                .map((e) => Experience.fromJson(e))
                .toList()
          : null,
      bankInformation: json['bankInformation'] != null
          ? BankInformation.fromJson(json['bankInformation'])
          : null,
      emergencyContacts: json['emergencyContacts'] != null
          ? (json['emergencyContacts'] as List)
                .map((e) => EmergencyContact.fromJson(e))
                .toList()
          : null,
      reportingManager: json['reportingManager'] != null
          ? ReportingManager.fromJson(json['reportingManager'])
          : null,
      manager: json['manager'] != null
          ? Manager.fromJson(json['manager'])
          : null,
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

class Department {
  final int id;
  final String name;
  final String? description;

  Department({required this.id, required this.name, this.description});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class Designation {
  final int id;
  final String name;
  final String? description;

  Designation({required this.id, required this.name, this.description});

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class Role {
  final int id;
  final String name;
  final String? description;

  Role({required this.id, required this.name, this.description});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
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

  Branch({required this.id, required this.name, this.address, this.tenantId});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      tenantId: json['tenantId'],
    );
  }
}

class Company {
  final int id;
  final String name;
  final String? description;

  Company({required this.id, required this.name, this.description});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class FamilyMember {
  final int id;
  final String name;
  final String relationship;
  final String? contactNumber;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.contactNumber,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      contactNumber: json['contactNumber'],
    );
  }
}

class Education {
  final int id;
  final String qualification;
  final String institution;
  final String? yearOfPassing;

  Education({
    required this.id,
    required this.qualification,
    required this.institution,
    this.yearOfPassing,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] ?? 0,
      qualification: json['qualification'] ?? '',
      institution: json['institution'] ?? '',
      yearOfPassing: json['yearOfPassing'],
    );
  }
}

class Experience {
  final int id;
  final String companyName;
  final String position;
  final String? duration;

  Experience({
    required this.id,
    required this.companyName,
    required this.position,
    this.duration,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] ?? 0,
      companyName: json['companyName'] ?? '',
      position: json['position'] ?? '',
      duration: json['duration'],
    );
  }
}

class BankInformation {
  final int id;
  final String bankName;
  final String accountNumber;
  final String? ifscCode;

  BankInformation({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    this.ifscCode,
  });

  factory BankInformation.fromJson(Map<String, dynamic> json) {
    return BankInformation(
      id: json['id'] ?? 0,
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'],
    );
  }
}

class EmergencyContact {
  final int id;
  final String name;
  final String relationship;
  final String contactNumber;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.contactNumber,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
    );
  }
}

class ReportingManager {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String empCode;

  ReportingManager({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.empCode,
  });

  factory ReportingManager.fromJson(Map<String, dynamic> json) {
    return ReportingManager(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      empCode: json['empCode'] ?? '',
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

class Manager {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String bloodGroup;
  final String email;
  final String empCode;

  Manager({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.bloodGroup,
    required this.email,
    required this.empCode,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      email: json['email'] ?? '',
      empCode: json['empCode'] ?? '',
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

class EmployeeResponse {
  final int code;
  final bool error;
  final String message;
  final EmployeeContent? content;

  EmployeeResponse({
    required this.code,
    required this.error,
    required this.message,
    this.content,
  });

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeResponse(
      code: json['code'] ?? 0,
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      content: json['content'] != null
          ? EmployeeContent.fromJson(json['content'])
          : null,
    );
  }
}

class EmployeeContent {
  final EmployeeResult? result;

  EmployeeContent({this.result});

  factory EmployeeContent.fromJson(Map<String, dynamic> json) {
    return EmployeeContent(
      result: json['result'] != null
          ? EmployeeResult.fromJson(json['result'])
          : null,
    );
  }
}

class EmployeeResult {
  final Employee? data;
  final Map<String, dynamic>? pagination;

  EmployeeResult({this.data, this.pagination});

  factory EmployeeResult.fromJson(Map<String, dynamic> json) {
    // API can return either { result: { ...employee fields... } }
    // or { result: { data: { ...employee fields... }, pagination: {...} } }
    final dynamic dataNode = json['data'];
    final Employee? employeeData;
    if (dataNode is Map<String, dynamic>) {
      employeeData = Employee.fromJson(dataNode);
    } else if (json['id'] != null || json['firstName'] != null) {
      // Flattened result: the result object itself is the employee
      employeeData = Employee.fromJson(json);
    } else {
      employeeData = null;
    }

    return EmployeeResult(data: employeeData, pagination: json['pagination']);
  }
}
