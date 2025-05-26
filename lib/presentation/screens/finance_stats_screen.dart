import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/models/finance_entry_model.dart';
import '../../../data/repositories/finance_repository.dart';

extension TakeLastExtension<T> on List<T> {
  List<T> takeLast(int n) {
    if (n >= length) return this;
    return sublist(length - n);
  }
}

class FinanceStatsScreen extends StatefulWidget {
  const FinanceStatsScreen({super.key});

  @override
  State<FinanceStatsScreen> createState() => _FinanceStatsScreenState();
}

class _FinanceStatsScreenState extends State<FinanceStatsScreen> {
  final _repo = FinanceRepository();

  List<FinanceEntryModel> allEntries = [];
  List<String> availableMonths = [];
  String selectedMonth = '';
  Map<String, double> gastosPorCategoria = {};
  double totalIngresos = 0;
  double totalGastos = 0;

  List<String> comparisonMonths = [];
  List<double> ingresosMensuales = [];
  List<double> gastosMensuales = [];

  @override
  void initState() {
    super.initState();
    _repo.getEntries().listen((items) {
      allEntries = items;
      availableMonths = _getUniqueMonths(items);
      selectedMonth = availableMonths.isNotEmpty ? availableMonths.last : '';
      _calcularEstadisticas();
      _calcularComparacion();
    });
  }

  List<String> _getUniqueMonths(List<FinanceEntryModel> items) {
    final months = items
        .map((e) => DateFormat('MMMM yyyy', 'es_ES').format(e.date))
        .toSet()
        .toList();
    months.sort((a, b) => a.compareTo(b));
    return months;
  }

  void _calcularEstadisticas() {
    final filtrado = allEntries.where((e) =>
        DateFormat('MMMM yyyy', 'es_ES').format(e.date) == selectedMonth);

    totalIngresos = 0;
    totalGastos = 0;
    gastosPorCategoria = {};

    for (var e in filtrado) {
      if (e.type == 'ingreso') {
        totalIngresos += e.amount;
      } else {
        totalGastos += e.amount;
        gastosPorCategoria[e.category] =
            (gastosPorCategoria[e.category] ?? 0) + e.amount;
      }
    }

    setState(() {});
  }

  void _calcularComparacion() {
    final Map<String, double> ingresos = {};
    final Map<String, double> gastos = {};

    for (var e in allEntries) {
      final mes = DateFormat('MMMM yyyy', 'es_ES').format(e.date);
      if (e.type == 'ingreso') {
        ingresos[mes] = (ingresos[mes] ?? 0) + e.amount;
      } else {
        gastos[mes] = (gastos[mes] ?? 0) + e.amount;
      }
    }

    comparisonMonths = _getUniqueMonths(allEntries).takeLast(6).toList();
    ingresosMensuales = comparisonMonths.map((m) => ingresos[m] ?? 0).toList();
    gastosMensuales = comparisonMonths.map((m) => gastos[m] ?? 0).toList();
  }

  String _getComparacionTexto() {
    if (comparisonMonths.length < 2) return '';
    final i0 = ingresosMensuales[comparisonMonths.length - 2];
    final i1 = ingresosMensuales.last;
    final g0 = gastosMensuales[comparisonMonths.length - 2];
    final g1 = gastosMensuales.last;

    final ingresoDiff = i1 - i0;
    final gastoDiff = g1 - g0;

    final ingresoTexto = ingresoDiff == 0
        ? '📥 Ingresos sin cambios'
        : ingresoDiff > 0
            ? '📈 Ingresos subieron \$${ingresoDiff.toStringAsFixed(2)}'
            : '📉 Ingresos bajaron \$${(-ingresoDiff).toStringAsFixed(2)}';

    final gastoTexto = gastoDiff == 0
        ? '📤 Gastos sin cambios'
        : gastoDiff > 0
            ? '📈 Gastos subieron \$${gastoDiff.toStringAsFixed(2)}'
            : '📉 Gastos bajaron \$${(-gastoDiff).toStringAsFixed(2)}';

    return '$ingresoTexto\n$gastoTexto';
  }

  Future<void> _exportCSV() async {
    final List<List<dynamic>> csvData = [
      ['Tipo', 'Categoría', 'Monto', 'Descripción', 'Fecha']
    ];

    final filtrado = allEntries.where((e) =>
        DateFormat('MMMM yyyy', 'es_ES').format(e.date) == selectedMonth);

    for (var e in filtrado) {
      csvData.add([
        e.type,
        e.category,
        e.amount.toStringAsFixed(2),
        e.description,
        DateFormat('dd/MM/yyyy').format(e.date),
      ]);
    }

    final String csv = const ListToCsvConverter().convert(csvData);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/finanzas_$selectedMonth.csv');
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📁 Exportado CSV: ${file.path}')),
    );
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final filtrado = allEntries.where((e) =>
        DateFormat('MMMM yyyy', 'es_ES').format(e.date) == selectedMonth);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Estadísticas - $selectedMonth',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Ingresos: \$${totalIngresos.toStringAsFixed(2)}'),
            pw.Text('Gastos: \$${totalGastos.toStringAsFixed(2)}'),
            pw.Text('Balance: \$${(totalIngresos - totalGastos).toStringAsFixed(2)}'),
            pw.SizedBox(height: 10),
            pw.Text('Movimientos:'),
            ...filtrado.map((e) => pw.Text(
                '• ${e.type.toUpperCase()} | ${e.category} | \$${e.amount.toStringAsFixed(2)} | ${e.description}')),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
  
  Widget _buildBarChart() {
    final categorias = gastosPorCategoria.keys.toList();
    final valores = gastosPorCategoria.values.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: valores.isEmpty ? 1 : (valores.reduce((a, b) => a > b ? a : b) + 10),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                return index < categorias.length
                    ? Transform.translate(
                        offset: const Offset(0, 6),
                        child: Text(
                          categorias[index],
                          style: const TextStyle(fontSize: 10),
                        ),
                      )
                    : const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(categorias.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: valores[i],
                width: 16,
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPieChart() {
    final total = totalIngresos + totalGastos;
    if (total == 0) return const Center(child: Text('No hay datos'));

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: totalIngresos,
            color: Colors.green,
            title: 'Ingresos\n${(totalIngresos / total * 100).toStringAsFixed(1)}%',
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
            radius: 60,
          ),
          PieChartSectionData(
            value: totalGastos,
            color: Colors.red,
            title: 'Gastos\n${(totalGastos / total * 100).toStringAsFixed(1)}%',
            titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
            radius: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: [
          ...ingresosMensuales,
          ...gastosMensuales,
        ].fold(0.0, (a, b) => a > b ? a : b) +
            20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                return index < comparisonMonths.length
                    ? Transform.translate(
                        offset: const Offset(0, 6),
                        child: Text(
                          comparisonMonths[index].substring(0, 3),
                          style: const TextStyle(fontSize: 10),
                        ),
                      )
                    : const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(comparisonMonths.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: ingresosMensuales[i],
                color: Colors.green,
                width: 7,
              ),
              BarChartRodData(
                toY: gastosMensuales[i],
                color: Colors.red,
                width: 7,
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = totalIngresos - totalGastos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Estadísticas financieras'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportCSV),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPDF),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: availableMonths.isEmpty
            ? const Center(child: Text('No hay datos disponibles'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: selectedMonth,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedMonth = value);
                          _calcularEstadisticas();
                        }
                      },
                      items: availableMonths
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('💰 Ingresos: \$${totalIngresos.toStringAsFixed(2)}'),
                    Text('💸 Gastos: \$${totalGastos.toStringAsFixed(2)}'),
                    Text('🧾 Balance: \$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        )),
                    const SizedBox(height: 24),
                    if (comparisonMonths.length >= 2) ...[
                      Text('📅 Comparativa últimos meses',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 180, child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: BarChartPlaceholder(),
                      )),
                      const SizedBox(height: 8),
                      Text(_getComparacionTexto()),
                      const Divider(height: 32),
                    ],
                    Text('📦 Gastos por categoría',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 180, child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: BarChartWrapper(),
                    )),
                    const SizedBox(height: 24),
                    Text('🥧 Reparto mensual',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 180, child: PieChartWrapper()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget BarChartWrapper() => _buildBarChart();
  Widget PieChartWrapper() => _buildPieChart();
  Widget BarChartPlaceholder() => _buildMonthlyComparisonChart();
}
