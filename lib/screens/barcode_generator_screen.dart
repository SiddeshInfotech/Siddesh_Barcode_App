import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class BarcodeGeneratorScreen extends StatelessWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Barcode Generator', style: AppTextStyles.sectionTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.purpleIconBg,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.purple,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Barcode Generator',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate and print custom product barcodes.',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
