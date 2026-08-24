import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class AttendancePdfPage extends StatelessWidget {
  final List<dynamic> students;
  final String filter;
  final DateTime date;

  const AttendancePdfPage({
    super.key,
    required this.students,
    required this.filter,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance PDF",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        build: (format) => _generatePdf(format),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final logo = await imageFromAssetBundle('assets/images/logo.png');

    final present = students
        .where((e) => e["AttendanceType"] == "Present")
        .length;
    final absent = students
        .where((e) => e["AttendanceType"] == "Absent")
        .length;
    final leave = students.where((e) => e["AttendanceType"] == "Leave").length;
    final halfDay = students
        .where((e) => e["AttendanceType"] == "HalfDay")
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),

        build: (context) => [
          /// HEADER
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue700,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Image(logo, width: 60, height: 60),

                pw.SizedBox(width: 15),

                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "SONIA PUBLIC SCHOOL",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 3),

                      pw.Text(
                        "Faridabad, Haryana",
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Attendance Report",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    pw.Text(
                      "Date : ${DateFormat("dd-MM-yyyy").format(date)}",
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),

                    pw.Text(
                      "Filter : $filter",
                      style: const pw.TextStyle(color: PdfColors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          /// SUMMARY
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _summary("Total", students.length.toString(), PdfColors.blue),
              _summary("Present", present.toString(), PdfColors.green),
              _summary("Absent", absent.toString(), PdfColors.red),
              _summary("Leave", leave.toString(), PdfColors.orange),
              _summary("Half Day", halfDay.toString(), PdfColors.indigo),
            ],
          ),

          pw.SizedBox(height: 20),

          /// TABLE
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              "S.No",
              "Roll No",
              "Student Name",
              "Father Name",
              "Status",
              "Date",
            ],
            data: List.generate(students.length, (index) {
              final s = students[index];

              return [
                "${index + 1}",
                "${s["RollNo"] ?? "-"}",
                "${s["StudentName"] ?? ""}",
                "${s["FatherName"] ?? ""}",
                "${s["AttendanceType"] ?? ""}",
                "${s["AttendanceDate"] ?? ""}",
              ];
            }),
          ),

          pw.SizedBox(height: 15),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Generated on ${DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now())}",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
    return Uint8List.fromList(await pdf.save());
  }

  pw.Widget _summary(String title, String value, PdfColor color) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: color,
              fontSize: 18,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(title),
        ],
      ),
    );
  }
}
