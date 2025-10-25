// Attendance related models - Updated to match TypeScript interfaces

// AttendanceFormData equivalent
class AttendanceFormData {
  final String employeeId;
  final String date;
  final String checkIn;
  final String checkOut;
  final String status; // "Present"
  final String? endDateTime;
  final String? startDateTime;

  AttendanceFormData({
    required this.employeeId,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.endDateTime,
    this.startDateTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'date': date,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'status': status,
      'endDateTime': endDateTime,
      'startDateTime': startDateTime,
    };
  }
}

// Summary equivalent
class Summary {
  final int present;
  final int absent;
  final int conflict;
  final int late;

  Summary({
    required this.present,
    required this.absent,
    required this.conflict,
    required this.late,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      present: json['Present'] ?? 0,
      absent: json['Absent'] ?? 0,
      conflict: json['Conflict'] ?? 0,
      late: json['Late'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Present': present,
      'Absent': absent,
      'Conflict': conflict,
      'Late': late,
    };
  }
}

// AttendanceEmployee equivalent
class AttendanceEmployee {
  final int id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? empcode;

  AttendanceEmployee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.empcode,
  });

  factory AttendanceEmployee.fromJson(Map<String, dynamic> json) {
    return AttendanceEmployee(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      middleName: json['middleName'],
      empcode: json['empcode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'empcode': empcode,
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

// AttendanceLog equivalent
class AttendanceLog {
  final int id;
  final int attendanceId;
  final String date;
  final int? shiftId;
  final int? deviceId;
  final String? lat;
  final String? lon;
  final String? ip;
  final String recordType;
  final String punchType; // "PunchIn" | "PunchOut"
  final String createdAt;
  final String updatedAt;

  AttendanceLog({
    required this.id,
    required this.attendanceId,
    required this.date,
    this.shiftId,
    this.deviceId,
    this.lat,
    this.lon,
    this.ip,
    required this.recordType,
    required this.punchType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      id: json['id'] ?? 0,
      attendanceId: json['attendanceId'] ?? 0,
      date: json['date'] ?? '',
      shiftId: json['shiftId'],
      deviceId: json['deviceId'],
      lat: json['lat'],
      lon: json['lon'],
      ip: json['ip'],
      recordType: json['recordType'] ?? '',
      punchType: json['punchType'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attendanceId': attendanceId,
      'date': date,
      'shiftId': shiftId,
      'deviceId': deviceId,
      'lat': lat,
      'lon': lon,
      'ip': ip,
      'recordType': recordType,
      'punchType': punchType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// AttendanceItem equivalent
class AttendanceItem {
  final int id;
  final String employeeId;
  final String date;
  final String checkIn;
  final String checkOut;
  final String status;
  final String attendanceDate;
  final String? punchInTime;
  final String? punchOutTime;
  final List<AttendanceLog> attendanceLogsId;
  final AttendanceEmployee attendance;

  AttendanceItem({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.attendanceDate,
    this.punchInTime,
    this.punchOutTime,
    required this.attendanceLogsId,
    required this.attendance,
  });

  factory AttendanceItem.fromJson(Map<String, dynamic> json) {
    return AttendanceItem(
      id: json['id'] ?? 0,
      employeeId: json['employeeId']?.toString() ?? '',
      date: json['date'] ?? '',
      checkIn: json['checkIn'] ?? '',
      checkOut: json['checkOut'] ?? '',
      status: json['status'] ?? '',
      attendanceDate: json['attendanceDate'] ?? '',
      punchInTime: json['punchInTime'],
      punchOutTime: json['punchOutTime'],
      attendanceLogsId: json['attendanceLogsId'] != null
          ? (json['attendanceLogsId'] as List)
              .map((e) => AttendanceLog.fromJson(e))
              .toList()
          : [],
      attendance: AttendanceEmployee.fromJson(json['attendance'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'status': status,
      'attendanceDate': attendanceDate,
      'punchInTime': punchInTime,
      'punchOutTime': punchOutTime,
      'attendanceLogsId': attendanceLogsId.map((e) => e.toJson()).toList(),
      'attendance': attendance.toJson(),
    };
  }
}

// AttendanceContent equivalent
class AttendanceContent {
  final int id;
  final int employeeId;
  final String punchInTime;
  final String punchOutTime;
  final String attendanceDate;
  final int earlyComingMinutes;
  final int lateComingMinutes;
  final int earlyDepartureMinutes;
  final int lateDepartureMinutes;
  final int? shiftId;
  final int? deviceId;
  final String? attendanceType;
  final String? location;
  final String status;
  final String createdAt;
  final String updatedAt;

  AttendanceContent({
    required this.id,
    required this.employeeId,
    required this.punchInTime,
    required this.punchOutTime,
    required this.attendanceDate,
    required this.earlyComingMinutes,
    required this.lateComingMinutes,
    required this.earlyDepartureMinutes,
    required this.lateDepartureMinutes,
    this.shiftId,
    this.deviceId,
    this.attendanceType,
    this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceContent.fromJson(Map<String, dynamic> json) {
    return AttendanceContent(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      punchInTime: json['punchInTime'] ?? '',
      punchOutTime: json['punchOutTime'] ?? '',
      attendanceDate: json['attendanceDate'] ?? '',
      earlyComingMinutes: json['earlyComingMinutes'] ?? 0,
      lateComingMinutes: json['lateComingMinutes'] ?? 0,
      earlyDepartureMinutes: json['earlyDepartureMinutes'] ?? 0,
      lateDepartureMinutes: json['lateDepartureMinutes'] ?? 0,
      shiftId: json['shiftId'],
      deviceId: json['deviceId'],
      attendanceType: json['attendanceType'],
      location: json['location'],
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'punchInTime': punchInTime,
      'punchOutTime': punchOutTime,
      'attendanceDate': attendanceDate,
      'earlyComingMinutes': earlyComingMinutes,
      'lateComingMinutes': lateComingMinutes,
      'earlyDepartureMinutes': earlyDepartureMinutes,
      'lateDepartureMinutes': lateDepartureMinutes,
      'shiftId': shiftId,
      'deviceId': deviceId,
      'attendanceType': attendanceType,
      'location': location,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// EmployeePunchingContent equivalent
class EmployeePunchingContent {
  final int id;
  final int employeeId;
  final String punchInTime;
  final String? punchOutTime;
  final String attendanceDate;
  final int earlyComingMinutes;
  final int lateComingMinutes;
  final int earlyDepartureMinutes;
  final int lateDepartureMinutes;
  final int productionHour;
  final String status;
  final String? remark;
  final String createdAt;
  final String updatedAt;
  final List<AttendanceLog> attendanceLogsId;

  EmployeePunchingContent({
    required this.id,
    required this.employeeId,
    required this.punchInTime,
    this.punchOutTime,
    required this.attendanceDate,
    required this.earlyComingMinutes,
    required this.lateComingMinutes,
    required this.earlyDepartureMinutes,
    required this.lateDepartureMinutes,
    required this.productionHour,
    required this.status,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
    required this.attendanceLogsId,
  });

  factory EmployeePunchingContent.fromJson(Map<String, dynamic> json) {
    return EmployeePunchingContent(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      punchInTime: json['punchInTime'] ?? '',
      punchOutTime: json['punchOutTime'],
      attendanceDate: json['attendanceDate'] ?? '',
      earlyComingMinutes: json['earlyComingMinutes'] ?? 0,
      lateComingMinutes: json['lateComingMinutes'] ?? 0,
      earlyDepartureMinutes: json['earlyDepartureMinutes'] ?? 0,
      lateDepartureMinutes: json['lateDepartureMinutes'] ?? 0,
      productionHour: json['productionHour'] ?? 0,
      status: json['status'] ?? '',
      remark: json['remark'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      attendanceLogsId: json['attendanceLogsId'] != null
          ? (json['attendanceLogsId'] as List)
              .map((e) => AttendanceLog.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'punchInTime': punchInTime,
      'punchOutTime': punchOutTime,
      'attendanceDate': attendanceDate,
      'earlyComingMinutes': earlyComingMinutes,
      'lateComingMinutes': lateComingMinutes,
      'earlyDepartureMinutes': earlyDepartureMinutes,
      'lateDepartureMinutes': lateDepartureMinutes,
      'productionHour': productionHour,
      'status': status,
      'remark': remark,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'attendanceLogsId': attendanceLogsId.map((e) => e.toJson()).toList(),
    };
  }
}

// AttendanceRecord equivalent
class AttendanceRecord {
  final String attendanceDate;
  final AttendanceEmployee? attendance;
  final String? punchInTime;
  final String? punchOutTime;
  final int earlyComingMinutes;
  final int lateComingMinutes;
  final int earlyDepartureMinutes;
  final int lateDepartureMinutes;
  final int productionHour;
  final String status;
  final List<AttendanceLog>? attendanceLogsId;

  AttendanceRecord({
    required this.attendanceDate,
    this.attendance,
    this.punchInTime,
    this.punchOutTime,
    required this.earlyComingMinutes,
    required this.lateComingMinutes,
    required this.earlyDepartureMinutes,
    required this.lateDepartureMinutes,
    required this.productionHour,
    required this.status,
    this.attendanceLogsId,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      attendanceDate: json['attendanceDate'] ?? '',
      attendance: json['attendance'] != null 
          ? AttendanceEmployee.fromJson(json['attendance']) 
          : null,
      punchInTime: json['punchInTime'],
      punchOutTime: json['punchOutTime'],
      earlyComingMinutes: json['earlyComingMinutes'] ?? 0,
      lateComingMinutes: json['lateComingMinutes'] ?? 0,
      earlyDepartureMinutes: json['earlyDepartureMinutes'] ?? 0,
      lateDepartureMinutes: json['lateDepartureMinutes'] ?? 0,
      productionHour: json['productionHour'] ?? 0,
      status: json['status'] ?? '',
      attendanceLogsId: json['attendanceLogsId'] != null
          ? (json['attendanceLogsId'] as List)
              .map((e) => AttendanceLog.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendanceDate': attendanceDate,
      'attendance': attendance?.toJson(),
      'punchInTime': punchInTime,
      'punchOutTime': punchOutTime,
      'earlyComingMinutes': earlyComingMinutes,
      'lateComingMinutes': lateComingMinutes,
      'earlyDepartureMinutes': earlyDepartureMinutes,
      'lateDepartureMinutes': lateDepartureMinutes,
      'productionHour': productionHour,
      'status': status,
      'attendanceLogsId': attendanceLogsId?.map((e) => e.toJson()).toList(),
    };
  }
}

// AttendanceUpdatePayload equivalent
class AttendanceUpdatePayload {
  final String date;
  final String employeeId;
  final String? punchInTime;
  final String? punchOutTime;
  final String status;
  final List<Map<String, dynamic>>? logdetails;
  final String? remark;

  AttendanceUpdatePayload({
    required this.date,
    required this.employeeId,
    this.punchInTime,
    this.punchOutTime,
    required this.status,
    this.logdetails,
    this.remark,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'employeeId': employeeId,
      'punchInTime': punchInTime,
      'punchOutTime': punchOutTime,
      'status': status,
      'logdetails': logdetails,
      'remark': remark,
    };
  }
}

// AttendanceResponse equivalent (for list)
class AttendanceResponse {
  final int code;
  final bool error;
  final String message;
  final String exception;
  final AttendanceResponseContent content;

  AttendanceResponse({
    required this.code,
    required this.error,
    required this.message,
    required this.exception,
    required this.content,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      code: json['code'] ?? 0,
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      exception: json['exception'] ?? '',
      content: AttendanceResponseContent.fromJson(json['content'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'error': error,
      'message': message,
      'exception': exception,
      'content': content.toJson(),
    };
  }
}

// AttendanceResponseContent equivalent
class AttendanceResponseContent {
  final List<AttendanceRecord> data;
  final AttendancePagination pagination;

  AttendanceResponseContent({
    required this.data,
    required this.pagination,
  });

  factory AttendanceResponseContent.fromJson(Map<String, dynamic> json) {
    return AttendanceResponseContent(
      data: json['data'] != null 
          ? (json['data'] as List).map((e) => AttendanceRecord.fromJson(e)).toList()
          : [],
      pagination: AttendancePagination.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

// AttendancePagination equivalent
class AttendancePagination {
  final int total;
  final int page;
  final int pages;
  final int limit;

  AttendancePagination({
    required this.total,
    required this.page,
    required this.pages,
    required this.limit,
  });

  factory AttendancePagination.fromJson(Map<String, dynamic> json) {
    return AttendancePagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 0,
      pages: json['pages'] ?? 0,
      limit: json['limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'pages': pages,
      'limit': limit,
    };
  }
}

// AttendanceByIdResponse equivalent
class AttendanceByIdResponse {
  final int code;
  final bool error;
  final String message;
  final String exception;
  final AttendanceContent content;

  AttendanceByIdResponse({
    required this.code,
    required this.error,
    required this.message,
    required this.exception,
    required this.content,
  });

  factory AttendanceByIdResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceByIdResponse(
      code: json['code'] ?? 0,
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      exception: json['exception'] ?? '',
      content: AttendanceContent.fromJson(json['content'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'error': error,
      'message': message,
      'exception': exception,
      'content': content.toJson(),
    };
  }
}

// EmployeePunchingDetailsResponse equivalent
class EmployeePunchingDetailsResponse {
  final int code;
  final bool error;
  final String message;
  final String exception;
  final EmployeePunchingContent content;

  EmployeePunchingDetailsResponse({
    required this.code,
    required this.error,
    required this.message,
    required this.exception,
    required this.content,
  });

  factory EmployeePunchingDetailsResponse.fromJson(Map<String, dynamic> json) {
    return EmployeePunchingDetailsResponse(
      code: json['code'] ?? 0,
      error: json['error'] ?? false,
      message: json['message'] ?? '',
      exception: json['exception'] ?? '',
      content: EmployeePunchingContent.fromJson(json['content'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'error': error,
      'message': message,
      'exception': exception,
      'content': content.toJson(),
    };
  }
}
