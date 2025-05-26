import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/finance_entry_model.dart';
import '../../../data/repositories/finance_repository.dart';

class CreateOrEditFinanceEntryScreen extends StatefulWidget {
  final FinanceEntryModel? existing;

  const CreateOrEditFinanceEntryScreen({super.key, this.existing});

  @override
  State<CreateOrEditFinanceEntryScreen> createState() => _CreateOrEditFinanceEntryScreenState();
}

class _CreateOrEditFinanceEntryScreenState extends State<CreateOrEditFinanceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FinanceRepository();

  late String _type;
  String? _category;
  late double _amount;
  late String _description;
  late DateTime _date;
  bool _isRecurring = false;
  String? _recurrence;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.existing!;
      _type = e.type;
      _category = e.category;
      _amount = e.amount;
      _description = e.description;
      _date = e.date;
      _isRecurring = e.isRecurring;
      _recurrence = e.recurrence;
    } else {
      _type = 'gasto';
      _category = null;
      _amount = 0.0;
      _description = '';
      _date = DateTime.now();
      _isRecurring = false;
      _recurrence = null;
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final entry = FinanceEntryModel(
      id: isEditing ? widget.existing!.id : '',
      userId: FirebaseAuth.instance.currentUser!.uid,
      type: _type,
      category: _category!,
      amount: _amount,
      description: _description,
      date: _date,
      isRecurring: _isRecurring,
      recurrence: _isRecurring ? _recurrence : null,
      createdAt: isEditing ? widget.existing!.createdAt : DateTime.now(),
    );

    if (isEditing) {
      await _repo.updateEntry(entry.id, entry);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✏️ Movimiento actualizado')),
      );
    } else {
      await _repo.addEntry(entry);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Movimiento creado')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '✏️ Editar movimiento' : '➕ Nuevo movimiento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SwitchListTile(
                title: const Text('¿Es un ingreso?'),
                value: _type == 'ingreso',
                onChanged: (val) {
                  setState(() => _type = val ? 'ingreso' : 'gasto');
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría'),
                value: _category,
                onChanged: (value) => setState(() => _category = value),
                items: const [
                  DropdownMenuItem(value: 'Comida', child: Text('🍽️ Comida')),
                  DropdownMenuItem(value: 'Transporte', child: Text('🚗 Transporte')),
                  DropdownMenuItem(value: 'Suscripciones', child: Text('📺 Suscripciones')),
                  DropdownMenuItem(value: 'Salud', child: Text('🏥 Salud')),
                  DropdownMenuItem(value: 'Otros', child: Text('📦 Otros')),
                ],
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: TextInputType.number,
                initialValue: isEditing ? _amount.toString() : '',
                validator: (value) => value!.isEmpty ? 'Obligatorio' : null,
                onSaved: (value) => _amount = double.tryParse(value!) ?? 0.0,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                initialValue: isEditing ? _description : '',
                onSaved: (value) => _description = value ?? '',
              ),
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              SwitchListTile(
                title: const Text('¿Recurrente?'),
                value: _isRecurring,
                onChanged: (val) {
                  setState(() {
                    _isRecurring = val;
                    if (!val) _recurrence = null;
                  });
                },
              ),
              if (_isRecurring)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  value: _recurrence,
                  onChanged: (value) => setState(() => _recurrence = value),
                  items: const [
                    DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                    DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                    DropdownMenuItem(value: 'anual', child: Text('Anual')),
                  ],
                  validator: (value) => value == null ? 'Selecciona frecuencia' : null,
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: Icon(isEditing ? Icons.edit : Icons.save),
                label: Text(isEditing ? 'Actualizar' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
