# Common Widgets & Gallery Usage

This doc explains how we build shared UI components under `lib/core/widgets/` and how to quickly preview/test them via `WidgetGalleryPage`.

## Structure
- `lib/core/widgets/` – shared, reusable widgets (buttons, cards, scaffolds, etc.).
- `lib/core/widgets/widget_gallery_page.dart` – a lightweight preview page to render one or a few widgets you’re working on. It’s **not** a catalog of everything; treat it as a scratchpad.

## Workflow for building a common widget
1. Create the widget in `lib/core/widgets/`, with a small API that allows configuration (labels, icons, loading states, etc.).
2. Add minimal styling that aligns with `AppTheme` (fonts/colors/shapes).
3. Keep the widget self-contained; avoid feature-specific imports.
4. If the widget needs to consume app theme colors or typography, read them from `Theme.of(context)`.

## Previewing in `WidgetGalleryPage`
The gallery is a simple page you can manually adjust to render the widgets you’re iterating on.

1. Open `lib/core/widgets/widget_gallery_page.dart`.
2. Import the widget(s) you want to preview, e.g.:
   ```dart
   import 'package:modular_pos/core/widgets/app_primary_button.dart';
   ```
3. Inside the `GridView` (or replace it temporarily), drop your widget in:
   ```dart
   const AppSectionCard(
     title: 'Primary Buttons',
     child: Column(
       children: [
         AppPrimaryButton(label: 'Default', onPressed: null),
         AppPrimaryButton(label: 'Loading', isLoading: true),
       ],
     ),
   ),
   ```
4. Run the app and open `/components` to view the gallery.
   - The route is public (no login needed) and shows the gallery with your current widgets.
5. When you’re done previewing a widget, you can remove or replace it with the next one you’re working on.

## Notes
- The gallery is meant for development only; don’t try to include every shared widget permanently.
- Keep shared widgets generic; feature-specific UI stays inside `lib/features/<feature>/...`.
- The `/components` route is configured in `lib/app.dart` and uses the existing theme.
