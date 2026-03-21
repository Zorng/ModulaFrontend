import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/widgets/media/network_image_view_type.dart';

void main() {
  test('buildNetworkImageViewType is stable for the same image inputs', () {
    final first = buildNetworkImageViewType(
      url: ' https://cdn.example.com/proof.jpg ',
      borderRadius: 12,
      fit: BoxFit.cover,
    );
    final second = buildNetworkImageViewType(
      url: 'https://cdn.example.com/proof.jpg',
      borderRadius: 12,
      fit: BoxFit.cover,
    );

    expect(first, second);
  });

  test('buildNetworkImageViewType changes when image rendering inputs change', () {
    final base = buildNetworkImageViewType(
      url: 'https://cdn.example.com/proof.jpg',
      borderRadius: 12,
      fit: BoxFit.cover,
    );
    final differentFit = buildNetworkImageViewType(
      url: 'https://cdn.example.com/proof.jpg',
      borderRadius: 12,
      fit: BoxFit.contain,
    );
    final differentRadius = buildNetworkImageViewType(
      url: 'https://cdn.example.com/proof.jpg',
      borderRadius: 16,
      fit: BoxFit.cover,
    );

    expect(differentFit, isNot(base));
    expect(differentRadius, isNot(base));
  });
}
