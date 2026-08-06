import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/scan_history_service.dart';

class OutwardEntryScreen extends StatefulWidget {
  const OutwardEntryScreen({
    super.key,
    this.product,
    this.scannedBarcode,
  });

  final Product? product;
  final String? scannedBarcode;

  @override
  State<OutwardEntryScreen> createState() => _OutwardEntryScreenState();
}

class _OutwardEntryScreenState extends State<OutwardEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late Product _activeProduct;

  @override
  void initState() {
    super.initState();
    _activeProduct = widget.product ??
        const Product(
          id: '0',
          barcode: '',
          name: 'Scanned Product',
          category: 'General',
          brand: 'Generic',
          model: 'Standard',
          currentStock: 0,
          minimumStock: 0,
          availableStock: 0,
          imageUrl: '',
          supplier: 'Siddesh Infotech',
        );
  }

  @override
  void didUpdateWidget(OutwardEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.product != oldWidget.product && widget.product != null) {
      setState(() {
        _activeProduct = widget.product!;
      });
    }
  }

  int _quantity = 1;
  late final TextEditingController _schoolNameController = TextEditingController(
    text: 'St. Xavier International School',
  );
  late final TextEditingController _contactPersonController = TextEditingController(
    text: 'Dr. Ramesh Kumar',
  );
  late final TextEditingController _mobileController = TextEditingController(
    text: '+91 98765 43210',
  );
  late final TextEditingController _invoiceNoController = TextEditingController(
    text: 'OUT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
  );
  late final TextEditingController _deliveredByController = TextEditingController(
    text: 'Siddesh Logistics Team',
  );
  late final TextEditingController _receiverNameController = TextEditingController(
    text: 'Ramesh Kumar',
  );

  String _outwardType = 'School Dispatch';
  bool _hasSigned = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _contactPersonController.dispose();
    _mobileController.dispose();
    _invoiceNoController.dispose();
    _deliveredByController.dispose();
    _receiverNameController.dispose();
    super.dispose();
  }

  void _saveOutwardEntry() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_quantity > _activeProduct.availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot dispatch $_quantity items. Available stock is only ${_activeProduct.availableStock}.',
            ),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      final targetBarcode = (widget.scannedBarcode != null && widget.scannedBarcode!.isNotEmpty)
          ? widget.scannedBarcode!
          : _activeProduct.barcode;
      final intId = int.tryParse(_activeProduct.id);

      debugPrint('================ OUTWARD ENTRY FLOW DEBUG ================');
      debugPrint('[STEP 1] Scanned barcode received: "$targetBarcode"');
      debugPrint('[STEP 2] Recording outward entry for product ${_activeProduct.name} (Qty: $_quantity)');
      debugPrint('======================================================');

      String confirmedStatus;
      try {
        // Update the database first; only proceed to the success message once the
        // backend confirms the committed status change.
        confirmedStatus = await ApiService().recordOutward(
          barcode: targetBarcode,
          quantity: _quantity,
          productId: intId,
        );
      } catch (e) {
        debugPrint('ERROR SAVING OUTWARD ENTRY: $e');
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });
        String msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // DB confirmed — now record history with the real, confirmed status.
      ScanHistoryService().addScan(
        barcode: targetBarcode,
        productName: _activeProduct.name,
        category: _activeProduct.category,
        entryType: 'Outward',
        quantity: _quantity,
      );
      debugPrint('[OUTWARD ENTRY] DB confirmed status: $confirmedStatus');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.orangeIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.orange,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Outward Entry Saved!',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dispatched $_quantity item(s) to ${_schoolNameController.text}.\nRemaining stock will be ${_activeProduct.currentStock - _quantity}.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pop(context); // Back to dashboard
                    },
                    child: const Text(
                      'Return to Dashboard',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

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
        title: const Text('Outward Entry Form', style: AppTextStyles.sectionTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Summary Header Card (Auto Filled)
                _ProductOutwardHeaderCard(product: _activeProduct),
                const SizedBox(height: 20),

                // Form Section Header
                const Text('Dispatch Details', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 14),

                // Quantity Stepper (Validated against available stock)
                _buildQuantityStepper(),
                const SizedBox(height: 14),

                // School Name / Institution
                _buildTextField(
                  controller: _schoolNameController,
                  label: 'School / Institution Name',
                  icon: Icons.school_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter recipient name' : null,
                ),
                const SizedBox(height: 14),

                // Contact Person & Mobile Number Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _contactPersonController,
                        label: 'Contact Person',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Invoice Number
                _buildTextField(
                  controller: _invoiceNoController,
                  label: 'Dispatch Invoice Number',
                  icon: Icons.receipt_rounded,
                ),
                const SizedBox(height: 14),

                // Outward Type Selector
                _buildOutwardTypeSelector(),
                const SizedBox(height: 14),

                // Delivered By & Receiver Name Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _deliveredByController,
                        label: 'Delivered By',
                        icon: Icons.local_shipping_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _receiverNameController,
                        label: 'Receiver Name',
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Digital Signature Field Widget
                _buildSignatureCard(),
                const SizedBox(height: 28),

                // Submit Save Outward Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      elevation: 4,
                      shadowColor: AppColors.orange.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveOutwardEntry,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.drive_file_move_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Save Outward Entry',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Outward Quantity', style: AppTextStyles.statTitle),
              const SizedBox(height: 2),
              Text(
                'Available: ${_activeProduct.availableStock} items',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onTap: _quantity > 1
                    ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onTap: _quantity < _activeProduct.availableStock
                    ? () {
                        setState(() {
                          _quantity++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutwardTypeSelector() {
    final types = ['School Dispatch', 'Direct Sale', 'Internal Transfer', 'Sample'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Outward Dispatch Type', style: AppTextStyles.statTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: types.map((type) {
              final isSelected = _outwardType == type;
              return ChoiceChip(
                label: Text(
                  type,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.orange,
                backgroundColor: AppColors.orangeIconBg.withValues(alpha: 0.5),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _outwardType = type;
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: _hasSigned
              ? AppColors.green.withValues(alpha: 0.5)
              : AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.draw_rounded, color: AppColors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Receiver Digital Signature', style: AppTextStyles.cardTitle),
                ],
              ),
              if (_hasSigned)
                const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),

          // Mock Digital Signature Pad Canvas Frame
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_hasSigned)
                  CustomPaint(
                    size: const Size(double.infinity, 90),
                    painter: _SignatureSamplePainter(),
                  )
                else
                  const Text(
                    'Sign here with finger',
                    style: AppTextStyles.cardSubtitle,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasSigned = !_hasSigned;
                  });
                },
                child: Text(
                  _hasSigned ? 'Clear Signature' : 'Sign Now',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.statTitle,
          prefixIcon: Icon(icon, color: AppColors.orange, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _ProductOutwardHeaderCard extends StatelessWidget {
  const _ProductOutwardHeaderCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.orangePastel,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Icon(Icons.inventory_2_rounded, size: 36, color: AppColors.orange);
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OUTWARD',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                    Text(
                      'Avail: ${product.availableStock}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('Barcode: ${product.barcode}', style: AppTextStyles.cardSubtitle),
                Text('Brand: ${product.brand} | Model: ${product.model}', style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: onTap == null
                ? AppColors.textSecondary.withValues(alpha: 0.1)
                : AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: onTap == null
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : AppColors.orange,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SignatureSamplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.6)
      ..cubicTo(size.width * 0.3, size.height * 0.2, size.width * 0.4, size.height * 0.9, size.width * 0.5, size.height * 0.4)
      ..cubicTo(size.width * 0.6, size.height * 0.1, size.width * 0.7, size.height * 0.8, size.width * 0.8, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
