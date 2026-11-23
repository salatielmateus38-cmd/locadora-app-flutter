import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

enum BadgeTone {
  green(Color(0xFFECFDF5), Color(0xFF047857)),
  blue(Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
  orange(Color(0xFFFFF7ED), Color(0xFFC2410C)),
  gray(Color(0xFFF1F5F9), Color(0xFF475569));

  const BadgeTone(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.gray});

  factory StatusBadge.vehicle(VehicleStatus status) => StatusBadge(
        status.label,
        tone: switch (status) {
          VehicleStatus.available => BadgeTone.green,
          VehicleStatus.rented => BadgeTone.blue,
          VehicleStatus.maintenance => BadgeTone.orange,
        },
      );

  factory StatusBadge.rental(RentalStatus status) =>
      StatusBadge(status.label, tone: status == RentalStatus.active ? BadgeTone.blue : BadgeTone.green);

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: tone.foreground, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Foto do carro sobre um fundo suave.
class VehicleImage extends StatelessWidget {
  const VehicleImage(this.vehicle, {super.key, this.height = 150, this.radius = 16});

  final Vehicle vehicle;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand50, AppColors.brand100],
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        vehicle.photo,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 48, color: AppColors.brand500),
      ),
    );
  }
}

class VehicleThumb extends StatelessWidget {
  const VehicleThumb(this.vehicle, {super.key});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 72, child: VehicleImage(vehicle, height: 52, radius: 12));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: AppColors.brand50, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.brand500),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C)))),
        ],
      ),
    );
  }
}

/// Linha "rótulo .......... valor" usada nos resumos financeiros.
class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class TotalBox extends StatelessWidget {
  const TotalBox(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 18)),
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFB91C1C) : AppColors.ink,
    ));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
