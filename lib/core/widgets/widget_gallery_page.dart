import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_primary_button.dart';
import 'package:modular_pos/core/widgets/app_section_card.dart';

class WidgetGalleryPage extends StatelessWidget {
  const WidgetGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Components'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final gridCount = isWide ? 2 : 1;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: gridCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 1.8 : 1.1,
              children: const [
                AppSectionCard(
                  title: 'Primary Buttons',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppPrimaryButton(label: 'Full width', onPressed: null),
                      SizedBox(height: 8),
                      AppPrimaryButton(
                        label: 'With icon',
                        icon: Icon(Icons.arrow_forward),
                        onPressed: null,
                      ),
                      SizedBox(height: 8),
                      AppPrimaryButton(
                        label: 'Loading',
                        isLoading: true,
                      ),
                    ],
                  ),
                ),
                AppSectionCard(
                  title: 'Cards',
                  child: Text(
                    'Use AppSectionCard to group related content with consistent '
                    'padding and title styling.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
