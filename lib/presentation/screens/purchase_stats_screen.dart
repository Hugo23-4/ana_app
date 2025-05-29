import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/shopping/data/models/shopping_item_model.dart';
import '../../features/shopping/domain/repositories/shopping_repository.dart';

class PurchaseStatsScreen extends StatefulWidget {
  const PurchaseStatsScreen({super.key});

  @override
  State<PurchaseStatsScreen> createState() => _PurchaseStatsScreenState();
}

class _PurchaseStatsScreenState extends State<PurchaseStatsScreen> {
  final ShoppingRepository _repo = ShoppingRepository();

  Map<String, int> categoryCount = {};
  int totalThisMonth = 0;
  int totalRecurring = 0;
  String selectedMonth = '';
  List<String> availableMonths = [];
  List<ShoppingItemModel> allBoughtItems = [];

  @override
  void initState() {
    super.initState();
    _repo.getItems().listen((items) {
      final bought = items.where((e) => e.isBought).toList();
      setState(() {
        allBoughtItems = bought;
        availableMonths = _getUniqueMonths(bought);
        selectedMonth = availableMonths.isNotEmpty ? availableMonths.last : '';
        _calculateStats();
      });
    });
  }

  List<String> _getUniqueMonths(List<ShoppingItemModel> items) {
    final months = items
        .map((e) => DateFormat('MMMM yyyy', 'es_ES').format(e.createdAt))
        .toSet()
        .toList();
    months.sort((a, b) => a.compareTo(b));
    return months;
  }

  void _calculateStats() {
    final filtered = allBoughtItems.where((item) {
      final mes = DateFormat('MMMM yyyy', 'es_ES').format(item.createdAt);
      return mes == selectedMonth;
    }).toList();

    final Map<String, int> count = {};
    int recurring = 0;
    for (var item in filtered) {
      count[item.category] = (count[item.category] ?? 0) + 1;
      if (item.isRecurring) recurring++;
    }

    setState(() {
      categoryCount = count;
      totalThisMonth = filtered.length;
      totalRecurring = recurring;
    });
  }

  Future<void> _exportCSV() async {
    final List<List<dynamic>> csvData = [
      ['Producto', 'Categoría', 'Fecha', '¿Recurrente?']
    ];

    final filtered = allBoughtItems.where((item) {
      final mes = DateFormat('MMMM yyyy', 'es_ES').format(item.createdAt);
      return mes == selectedMonth;
    }).toList();

    for (var item in filtered) {
      csvData.add([
        item.name,
        item.category,
        DateFormat('dd/MM/yyyy').format(item.createdAt),
        item.isRecurring ? 'Sí' : 'No'
      ]);
    }

    final String csv = const ListToCsvConverter().convert(csvData);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/compras_$selectedMonth.csv');
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📁 Exportado como CSV: ${file.path}')),
    );
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final filtered = allBoughtItems.where((item) {
      final mes = DateFormat('MMMM yyyy', 'es_ES').format(item.createdAt);
      return mes == selectedMonth;
    }).toList();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Historial de compras - $selectedMonth',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...filtered.map((item) => pw.Text(
                  '• ${item.name} | ${item.category} | ${DateFormat('dd/MM/yyyy').format(item.createdAt)} | ${item.isRecurring ? 'Recurrente' : 'No recurrente'}')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Widget _buildBarChart() {
    final categories = categoryCount.keys.toList();
    final values = categoryCount.values.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b)).toDouble() + 1,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return index < categories.length
                    ? Transform.translate(
                        offset: Offset(0, 6),
                        child: Text(categories[index], style: TextStyle(fontSize: 10)),
                      )
                    : Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(categories.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i].toDouble(),
                width: 16,
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPieChart() {
    final total = categoryCount.values.fold(0, (a, b) => a + b);
    if (total == 0) return const Center(child: Text('No hay datos'));

    final categories = categoryCount.keys.toList();
    final values = categoryCount.values.toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(categories.length, (i) {
          final percent = (values[i] / total * 100).toStringAsFixed(1);
          return PieChartSectionData(
            color: Colors.primaries[i % Colors.primaries.length],
            value: values[i].toDouble(),
            title: '${categories[i]} \n$percent%',
            radius: 60,
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = categoryCount.values.fold(0, (a, b) => a + b);
    final recurringPercent = total == 0 ? 0 : ((totalRecurring / total) * 100).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Estadísticas de compras'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.download), tooltip: 'Exportar CSV', onPressed: _exportCSV),
          IconButton(icon: const Icon(Icons.picture_as_pdf), tooltip: 'Exportar PDF', onPressed: _exportPDF),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/finanzas'),
        icon: const Icon(Icons.account_balance_wallet),
        label: const Text('Ir a Finanzas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: availableMonths.isEmpty
            ? const Center(child: Text('No hay datos disponibles'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: selectedMonth,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMonth = value);
                        _calculateStats();
                      }
                    },
                    items: availableMonths
                        .map((mes) => DropdownMenuItem(value: mes, child: Text(mes)))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('🧾 Compras: $totalThisMonth'),
                  Text('🔁 Recurrentes: $totalRecurring ($recurringPercent%)'),
                  const SizedBox(height: 24),
                  Text('📦 Por categoría', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 200, child: _buildBarChart()),
                  const SizedBox(height: 12),
                  Text('🥧 Gráfico de pastel', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 200, child: _buildPieChart()),
                ],
              ),
      ),
    );
  }
}