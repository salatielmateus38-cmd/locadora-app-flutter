import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Cadastro e edição de veículos (apenas administradores).
class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _plate;
  late final TextEditingController _color;
  late final TextEditingController _rate;
  late VehicleCategory _category;
  late VehicleStatus _status;
  String? _error;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brand = TextEditingController(text: v?.brand);
    _model = TextEditingController(text: v?.model);
    _year = TextEditingController(text: v?.year.toString() ?? '${DateTime.now().year}');
    _plate = TextEditingController(text: v?.plate);
    _color = TextEditingController(text: v?.color);
    _rate = TextEditingController(text: v?.dailyRate.toStringAsFixed(2).replaceAll('.', ','));
    _category = v?.category ?? VehicleCategory.hatch;
    _status = v?.status ?? VehicleStatus.available;
  }

  @override
  void dispose() {
    for (final c in [_brand, _model, _year, _plate, _color, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Aceita "129,90", "1.299,90" e "129.90".
  double? _parseRate(String text) {
    final value = text.trim();
    final normalized = value.contains(',') ? value.replaceAll('.', '').replaceAll(',', '.') : value;
    return double.tryParse(normalized);
  }

  void _submit() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final store = StoreScope.read(context);
    try {
      final year = int.parse(_year.text.trim());
      final rate = _parseRate(_rate.text)!;
      if (_isEditing) {
        store.updateVehicle(
          widget.vehicle!.id,
          brand: _brand.text,
          model: _model.text,
          year: year,
          plate: _plate.text,
          color: _color.text,
          category: _category,
          dailyRate: rate,
          status: _status,
        );
      } else {
        store.addVehicle(
          brand: _brand.text,
          model: _model.text,
          year: year,
          plate: _plate.text,
          color: _color.text,
          category: _category,
          dailyRate: rate,
          status: _status,
        );
      }
      showMessage(context, _isEditing ? 'Veículo atualizado' : 'Veículo cadastrado');
      Navigator.pop(context);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  String? _required(String? value, String message) => (value == null || value.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final isRented = widget.vehicle?.status == VehicleStatus.rented;
    final maxYear = DateTime.now().year + 1;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar veículo' : 'Novo veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brand,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Marca'),
                    validator: (v) => (v ?? '').trim().length < 2 ? 'Marca é obrigatória' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _model,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                    validator: (v) => _required(v, 'Modelo é obrigatório'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    decoration: const InputDecoration(labelText: 'Ano'),
                    validator: (v) {
                      final year = int.tryParse(v ?? '');
                      return year == null || year < 1990 || year > maxYear ? 'Entre 1990 e $maxYear' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [LengthLimitingTextInputFormatter(8)],
                    decoration: const InputDecoration(labelText: 'Placa', hintText: 'ABC1D23'),
                    validator: (v) => AppStore.plateRegex.hasMatch(AppStore.normalizePlate(v ?? ''))
                        ? null
                        : 'Placa inválida',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _color,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Cor'),
                    validator: (v) => (v ?? '').trim().length < 2 ? 'Cor é obrigatória' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _rate,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Diária (R\$)', hintText: '129,90'),
                    validator: (v) {
                      final rate = _parseRate(v ?? '');
                      return rate == null || rate <= 0 ? 'Valor inválido' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VehicleCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                for (final c in VehicleCategory.values) DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<VehicleStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                helperText: isRented ? 'Veículo locado: registre a devolução para alterar o status.' : null,
              ),
              items: [
                for (final s in VehicleStatus.values)
                  if (s != VehicleStatus.rented || isRented) DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: isRented ? null : (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(_isEditing ? 'Salvar' : 'Cadastrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
