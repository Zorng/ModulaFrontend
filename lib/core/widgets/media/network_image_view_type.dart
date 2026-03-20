import 'package:flutter/material.dart';

String buildNetworkImageViewType({
  required String url,
  required double borderRadius,
  required BoxFit fit,
}) {
  final normalizedUrl = url.trim();
  return 'network-img-${normalizedUrl.hashCode}-${normalizedUrl.length}-${borderRadius.toStringAsFixed(2)}-${fit.index}';
}
