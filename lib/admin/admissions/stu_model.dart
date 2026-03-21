class StudentModel {
  final int id;
  final String studentName;
  final String fatherName;
  final String ledgerNo;
  final String rollNo;
  final String dob;
  final String contactNo;
  final String address;
  final String photo;
  final String className;
  final String section;

  StudentModel({
    required this.id,
    required this.studentName,
    required this.fatherName,
    required this.ledgerNo,
    required this.rollNo,
    required this.dob,
    required this.contactNo,
    required this.address,
    required this.photo,
    required this.className,
    required this.section,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      studentName: json['StudentName']?.toString() ?? '',
      fatherName: json['FatherName']?.toString() ?? '',
      ledgerNo: json['LedgerNo']?.toString() ?? '',
      rollNo: json['RollNo']?.toString() ?? '',
      dob: json['DOB']?.toString() ?? '',
      contactNo: json['ContactNo']?.toString() ?? '',
      address: json['Address']?.toString() ?? '',
      photo: json['Photo']?.toString() ?? '',
      className: json['Class']?.toString() ?? '',
      section: json['Section']?.toString() ?? '',
    );
  }
}
