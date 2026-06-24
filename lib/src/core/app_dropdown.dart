import 'package:flutter/material.dart';

/// A drop-in replacement for [DropdownButtonFormField] with the app's modern look: a rounded,
/// tinted popup menu (instead of the default square white sheet), a soft chevron, and full-width
/// items. Takes the same arguments, so migrating a call site is just renaming the constructor.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    this.initialValue,
    this.decoration,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isExpanded = true,
  });

  final T? initialValue;
  final InputDecoration? decoration;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration: decoration,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      // The bits that lift the default dropdown out of "phèn" territory.
      borderRadius: BorderRadius.circular(16),
      dropdownColor: scheme.surfaceContainerHigh,
      elevation: 3,
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: scheme.onSurfaceVariant),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
