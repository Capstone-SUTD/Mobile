import 'dart:convert';

//import 'package:capstone_app/mobile_screens/new_project_form.dart';

class Project {
  final String client;
  final String projectId;
  final String projectName;
  final String projectType;
  final String startDestination;
  final String endDestination;
  final String projectStatus;
  final DateTime startDate;
  final String emailsubjectheader;
  final String? stage;
  final bool? msra;
  List<Stakeholder> stakeholders;
  final List<Cargo> cargo;
  final List<Scope> scope;

  Project({
    required this.client,
    required this.projectId,
    required this.projectName,
    required this.projectType,
    required this.startDestination,
    required this.endDestination,
    required this.projectStatus,
    required this.startDate,
    required this.emailsubjectheader,
    this.stage,
    this.msra,
    required this.stakeholders,
    required this.cargo,
    required this.scope,
  });

  // Factory constructor to parse JSON into Dart object
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      client: json['client']?.toString() ?? "",
      projectId: json['projectid'].toString(), // match API key
      projectName: json['projectname'] ?? "",
      projectType: json['projecttype'] ?? "",
      startDestination: json['startdestination'] ?? "",
      endDestination: json['enddestination'] ?? "",
      projectStatus: json['projectStatus'] ?? "New", 
      emailsubjectheader: json['emailsubjectheader'].toString() ?? "",
      stage: json['stage'],
      msra: json['MSRA'],
      startDate: DateTime.tryParse(json['startdate']) ?? DateTime.now(),
      stakeholders: (json['stakeholders'] as List<dynamic>? ?? [])
          .map((item) => Stakeholder.fromJson(item))
          .toList(),
      cargo: (json['cargo'] as List<dynamic>? ?? [])
          .map((item) => Cargo.fromJson(item))
          .toList(),
      scope: (json['scope'] as List<dynamic>? ?? [])
          .map((item) => Scope.fromJson(item))
          .toList(),
    );
  }

  // Convert Dart object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'client': client,
      'projectId': projectId,
      'projectname': projectName,
      'projecttype': projectType,
      'startdestination': startDestination,
      'enddestination': endDestination,
      'projectstatus': projectStatus,
      'emailsubjectheader': emailsubjectheader,
      'startdate': startDate.toIso8601String(),
      'stage': stage,
      'msra': msra,
      'stakeholders': stakeholders.map((item) => item.toJson()).toList(),
      'cargo': cargo.map((item) => item.toJson()).toList(),
      'scope': scope.map((item) => item.toJson()).toList(),
    };
  }

  // Helper function to convert date format from "DD/MM/YYYY" to "YYYY-MM-DD"
  /**static String _convertDateFormat(String date) {
    List<String> parts = date.split('/');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }**/

  // ✅ ADD THIS METHOD TO ALLOW UPDATING FIELDS
  Project copyWith({
    String? client,
    String? projectId,
    String? projectName,
    String? projectType,
    String? startDestination,
    String? endDestination,
    String? projectStatus,
    DateTime? startDate,
    String? emailsubjectheader,
    String? stage,
    List<Stakeholder>? stakeholders,
    List<Cargo>? cargo,
    List<Scope>? scope,
  }) {
      return Project(
        client: client ?? this.client,
        projectId: projectId ?? this.projectId,
        projectName: projectName ?? this.projectName,
        projectType: projectType ?? this.projectType,
        startDestination: startDestination ?? this.startDestination,
        endDestination: endDestination ?? this.endDestination,
        projectStatus: projectStatus ?? this.projectStatus,
        startDate: startDate ?? this.startDate,
        emailsubjectheader: emailsubjectheader ?? this.emailsubjectheader,
        stage: stage ?? this.stage,
        stakeholders: stakeholders ?? this.stakeholders,
        cargo: cargo ?? this.cargo,
        scope: scope ?? this.scope,
      );
  }
}

class Stakeholder {
  final int userId;
  final String role;
  String? name;
  String? email;
  String? comments;

  Stakeholder({
    required this.userId,
    required this.role,
    this.name,
    this.email,
    this.comments,
  });

  factory Stakeholder.fromJson(Map<String, dynamic> json) {
    return Stakeholder(
      userId: int.parse(json['userid'].toString()),
      role: json['role'],
      name: json['name'],
      email: json['email'],
      comments: json['comments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'name' : name,
      'email' : email,
      'comments' : comments,
    };
  }
}


// Cargo Model
class Cargo {
  String cargoname;
  String length;
  String breadth;
  String height;
  String weight;
  String quantity;
  String result;

  Cargo({
    required this.cargoname,
    required this.length,
    required this.breadth,
    required this.height,
    required this.weight,
    required this.quantity,
    required this.result,
  });

  factory Cargo.fromJson(Map<String, dynamic> json) {
    return Cargo(
      cargoname: json['cargoname'],
      length: json['length'].toString(),
      breadth: json['breadth'].toString(),
      height: json['height'].toString(),
      weight: json['weight'].toString(),
      quantity: json['quantity'].toString(),
      result : json['oog'] ? "OOG" : "Normal",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargoname': cargoname,
      'length': length,
      'breadth': breadth,
      'height': height,
      'weight': weight,
      'quantity': quantity,
      'result' : result,
    };
  }
}

// Scope Model
class Scope {
  final String startdestination;
  final String enddestination;
  final String scope;
  final String equipmentList;

  Scope({
    required this.startdestination,
    required this.enddestination,
    required this.scope,
    required this.equipmentList,
  });

  factory Scope.fromJson(Map<String, dynamic> json) {
    return Scope(
      startdestination: json['start'],
      enddestination: json['end'],
      scope: json['work'],
      equipmentList: json['equipment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startdestination': startdestination,
      'enddestination' : enddestination,
      'scope': scope,
      'equipmentList': equipmentList,
    };
  }
}