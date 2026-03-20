import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';

class ManualKhqrClaimDraft {
  const ManualKhqrClaimDraft({
    required this.claimedTenderAmount,
    required this.proofImageBytes,
    this.customerReference,
    this.note,
  });

  final double claimedTenderAmount;
  final Uint8List proofImageBytes;
  final String? customerReference;
  final String? note;
}

Future<ManualKhqrClaimDraft?> showManualKhqrClaimDialog(
  BuildContext context, {
  required String tenderCurrency,
  required double initialAmount,
  String title = 'Add External Payment Claim Proof',
  String introText =
      'This stores the external payment claim proof locally on the outage order. Final approval still happens later when the order is reviewed online.',
  String saveLabel = 'Save Claim Details',
}) async {
  final picker = ImagePicker();
  final amountController = TextEditingController(
    text: tenderCurrency.toLowerCase() == 'khr'
        ? initialAmount.toStringAsFixed(0)
        : initialAmount.toStringAsFixed(2),
  );
  final referenceController = TextEditingController();
  final noteController = TextEditingController();
  Uint8List? selectedImageBytes;

  try {
    return await showDialog<ManualKhqrClaimDraft>(
      context: context,
      builder: (dialogContext) {
        String? validationMessage;
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      introText,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            'Claimed amount (${tenderCurrency.toUpperCase()})',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Payment proof',
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    ProductImagePicker(
                      onPickImage: () async {
                        try {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          if (bytes.isEmpty) {
                            setModalState(() {
                              validationMessage =
                                  'Selected proof image is empty. Please pick another image.';
                            });
                            return;
                          }
                          setModalState(() {
                            selectedImageBytes = bytes;
                            validationMessage = null;
                          });
                        } catch (_) {
                          setModalState(() {
                            validationMessage =
                                'Image picker is not available right now. Restart the app after flutter pub get if needed.';
                          });
                        }
                      },
                      imageBytes: selectedImageBytes,
                      placeholderLabel: 'Select proof image',
                      placeholderIcon: Icons.add_photo_alternate_outlined,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Customer reference (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                      ),
                    ),
                    if (validationMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        validationMessage!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount <= 0) {
                      setModalState(() {
                        validationMessage =
                            'Enter a valid claimed amount before saving.';
                      });
                      return;
                    }
                    if (selectedImageBytes == null ||
                        selectedImageBytes!.isEmpty) {
                      setModalState(() {
                        validationMessage =
                            'Select the customer payment proof image before saving.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      ManualKhqrClaimDraft(
                        claimedTenderAmount: amount,
                        proofImageBytes: selectedImageBytes!,
                        customerReference: referenceController.text.trim(),
                        note: noteController.text.trim(),
                      ),
                    );
                  },
                  child: Text(saveLabel),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    amountController.dispose();
    referenceController.dispose();
    noteController.dispose();
  }
}
