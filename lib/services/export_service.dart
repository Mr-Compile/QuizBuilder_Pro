import 'package:collection/collection.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/question.dart';
import '../database/database_helper.dart';

/// Service for exporting quiz results to PDF and Excel formats.
class ExportService {
  final DatabaseHelper _db;

  ExportService(this._db);

  /// Export quiz result to PDF
  Future<void> exportToPdf(int resultId) async {
    final results = await _db.getAllResults();
    final result = results.where((r) => r.id == resultId).firstOrNull;
    if (result == null) return;

    final topic = await _db.getTopicById(result.topicId);
    final answers = await _db.getAnswersForResult(resultId);

    // Pre-fetch all questions
    final questions = <int, Question>{};
    for (final answer in answers) {
      final question = await _db.getQuestionById(answer.questionId);
      if (question != null) {
        questions[answer.questionId] = question;
      }
    }

    final pdf = pw.Document();
    
    // Build PDF content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Quiz Result Report'),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Topic: ${topic?.name ?? "Unknown"}'),
              pw.Text('Difficulty: ${result.difficulty}'),
              pw.Text('Date: ${result.createdAt}'),
              pw.Text('Score: ${result.score}/${result.totalQuestions}'),
              pw.Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
              pw.SizedBox(height: 20),
              pw.Header(level: 1, child: pw.Text('Answer Details')),
              pw.SizedBox(height: 10),
              ...answers.map((answer) {
                final question = questions[answer.questionId];
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Question: ${question?.question ?? "N/A"}'),
                    pw.Text('Your Answer: ${answer.userAnswer}'),
                    pw.Text('Correct Answer: ${answer.correctAnswer}'),
                    pw.Text('Result: ${answer.isCorrect ? "Correct" : "Incorrect"}'),
                    pw.SizedBox(height: 10),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    // Share PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/quiz_result_$resultId.pdf');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: 'Quiz Result PDF');
  }

  /// Export quiz result to Excel
  Future<void> exportToExcel(int resultId) async {
    final results = await _db.getAllResults();
    final result = results.where((r) => r.id == resultId).firstOrNull;
    if (result == null) return;

    final topic = await _db.getTopicById(result.topicId);
    final answers = await _db.getAnswersForResult(resultId);

    // Pre-fetch all questions
    final questions = <int, Question>{};
    for (final answer in answers) {
      final question = await _db.getQuestionById(answer.questionId);
      if (question != null) {
        questions[answer.questionId] = question;
      }
    }

    final excel = Excel.createExcel();
    final sheet = excel['Quiz Results'];

    // Add headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Question');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Your Answer');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('Correct Answer');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('Result');

    // Add data
    for (int i = 0; i < answers.length; i++) {
      final answer = answers[i];
      final question = questions[answer.questionId];
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(question?.question ?? 'N/A');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(answer.userAnswer);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(answer.correctAnswer);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = TextCellValue(answer.isCorrect ? 'Correct' : 'Incorrect');
    }

    // Add summary
    final summaryRow = answers.length + 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow)).value = TextCellValue('Topic');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow)).value = TextCellValue(topic?.name ?? 'Unknown');
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 1)).value = TextCellValue('Difficulty');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 1)).value = TextCellValue(result.difficulty);
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 2)).value = TextCellValue('Score');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 2)).value = TextCellValue('${result.score}/${result.totalQuestions}');
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow + 3)).value = TextCellValue('Percentage');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: summaryRow + 3)).value = TextCellValue('${result.percentage.toStringAsFixed(1)}%');

    // Save and share
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/quiz_result_$resultId.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Quiz Result Excel');
    }
  }

  /// Export all results to Excel (for teachers)
  Future<void> exportAllResultsToExcel() async {
    final results = await _db.getAllResults();
    final excel = Excel.createExcel();
    final sheet = excel['All Quiz Results'];

    // Add headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Date');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Topic');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('Difficulty');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('Score');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue('Total Questions');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 0)).value = TextCellValue('Percentage');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 0)).value = TextCellValue('Passed');

    // Add data
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final topic = await _db.getTopicById(result.topicId);
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(result.createdAt);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(topic?.name ?? 'Unknown');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = TextCellValue(result.difficulty);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = IntCellValue(result.score);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = IntCellValue(result.totalQuestions);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = TextCellValue('${result.percentage.toStringAsFixed(1)}%');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = TextCellValue(result.passed ? 'Yes' : 'No');
    }

    // Save and share
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/all_quiz_results.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'All Quiz Results Excel');
    }
  }
}
