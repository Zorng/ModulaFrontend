import 'package:flutter/material.dart';
import 'package:modular_pos/features/sale/ui/components/view_carts/view_carts_formatters.dart';

class ViewCartsFilters extends StatelessWidget {
  const ViewCartsFilters({
    super.key,
    required this.selectedDate,
    required this.selectedState,
    required this.states,
    required this.onPickDate,
    required this.onStateSelected,
  });

  final DateTime selectedDate;
  final String selectedState;
  final List<String> states;
  final VoidCallback onPickDate;
  final ValueChanged<String> onStateSelected;

  @override
  Widget build(BuildContext context) {
    final dateLabel = viewCartsFormatDate(selectedDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(dateLabel),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final state = states[index];
              return ChoiceChip(
                label: Text(viewCartsStateLabel(state)),
                selected: selectedState == state,
                onSelected: (_) => onStateSelected(state),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: states.length,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
