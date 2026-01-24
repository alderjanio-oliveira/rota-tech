import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class KmReportPdfService {
  static Future<void> generate({required String deviceName, required List<DailyDistance> data}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Relatório de Quilometragem', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Veículo: $deviceName'),
              pw.SizedBox(height: 16),
              _buildTable(data),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static pw.Widget _buildTable(List<DailyDistance> data) {
    return pw.Table.fromTextArray(
      headers: ['Data', 'Km'],
      data: data.map((e) {
        return [DateFormat('dd/MM/yyyy').format(e.day), e.km.toStringAsFixed(2)];
      }).toList(),
    );
  }
}
