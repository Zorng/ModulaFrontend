import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/media/network_image_helper_stub.dart'
    if (dart.library.html) 'package:modular_pos/core/widgets/media/network_image_helper_web.dart';

class SaleItemDetailImage extends StatelessWidget {
  const SaleItemDetailImage({super.key, this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final placeholder = Container(
      alignment: Alignment.center,
      child: const Icon(Icons.local_cafe_outlined, size: 48),
    );
    if (!hasUrl) return placeholder;
    return buildAdaptiveNetworkImage(imageUrl!, placeholder);
  }
}
