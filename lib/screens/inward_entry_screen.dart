import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/product_model.dart';

class InwardEntryScreen extends StatefulWidget {
  const InwardEntryScreen({
    super.key,
    this.product,
  });

  final Product? product;

  @override
  State<InwardEntryScreen> createState() => _InwardEntryScreenState();
}

class _InwardEntryScreenState extends State<InwardEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Product _activeProduct = widget.product ??
      const Product(
        id: 'PRD-DEFAULT',
        barcode: '8901234567890',
        name: 'Wireless Industrial Barcode Scanner X1',
        category: 'Electronics & Scanners',
        brand: 'ZebraTech',
        model: 'ZT-9000-HD',
        currentStock: 142,
        minimumStock: 25,
        availableStock: 130,
        imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500',
        supplier: 'Apex Tech Solutions Ltd.',
      );

  int _quantity = 1;
  late final TextEditingController _invoiceNoController = TextEditingController(
    text: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
  );
  late final TextEditingController _purchaseOrderController = TextEditingController(
    text: 'PO-2026-9021',
  );
  late final TextEditingController _receivedByController = TextEditingController(
    text: 'Siddesh (Warehouse Mgr)',
  );

  DateTime _invoiceDate = DateTime.now();
  String? _uploadedFileName;
  bool _isSaving = false;

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _purchaseOrderController.dispose();
    _receivedByController.dispose();
    super.dispose();
  }

  Future<void> _selectInvoiceDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBg,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _invoiceDate) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  void _saveInwardEntry() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      await Future.delayed(const Duration(milliseconds: 900));

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
                    color: AppColors.greenPastel,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.green,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Inward Entry Saved!',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Added $_quantity item(s) to ${_activeProduct.name}.\nUpdated stock will be ${_activeProduct.currentStock + _quantity}.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
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
        title: const Text('Inward Entry Form', style: AppTextStyles.sectionTitle),
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
                _ProductHeaderCard(product: _activeProduct, badgeColor: AppColors.green, modeLabel: 'INWARD'),
                const SizedBox(height: 20),

                // Form Section Header
                const Text('Entry Details', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 14),

                // Auto-filled Supplier Field
                _ReadonlyField(
                  label: 'Supplier',
                  value: _activeProduct.supplier,
                  icon: Icons.business_rounded,
                ),
                const SizedBox(height: 14),

                // Quantity Editable Stepper & Input
                _buildQuantityStepper(),
                const SizedBox(height: 14),

                // Invoice Number Field
                _buildTextField(
                  controller: _invoiceNoController,
                  label: 'Invoice Number',
                  icon: Icons.receipt_long_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter invoice number' : null,
                ),
                const SizedBox(height: 14),

                // Invoice Date Picker Field
                InkWell(
                  onTap: () => _selectInvoiceDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Invoice Date', style: AppTextStyles.statTitle),
                                const SizedBox(height: 2),
                                Text(
                                  '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                                  style: AppTextStyles.cardTitle,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Purchase Order Field
                _buildTextField(
                  controller: _purchaseOrderController,
                  label: 'Purchase Order (PO)',
                  icon: Icons.assignment_rounded,
                ),
                const SizedBox(height: 14),

                // Received By Field
                _buildTextField(
                  controller: _receivedByController,
                  label: 'Received By',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                // Upload Invoice File Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.mintPastel,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.green, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Invoice Document', style: AppTextStyles.cardTitle),
                            const SizedBox(height: 2),
                            Text(
                              _uploadedFileName ?? 'PDF, PNG or JPG (Max 5MB)',
                              style: AppTextStyles.cardSubtitle,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _uploadedFileName = 'Invoice_${_invoiceNoController.text}.pdf';
                          });
                        },
                        child: Text(
                          _uploadedFileName == null ? 'Upload' : 'Change',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Save Inward Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      elevation: 4,
                      shadowColor: AppColors.green.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveInwardEntry,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Save Inward Entry',
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inward Quantity', style: AppTextStyles.statTitle),
              SizedBox(height: 2),
              Text('Units to add', style: AppTextStyles.cardSubtitle),
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
                onTap: () {
                  setState(() {
                    _quantity++;
                  });
                },
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
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.statTitle,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _ProductHeaderCard extends StatelessWidget {
  const _ProductHeaderCard({
    required this.product,
    required this.badgeColor,
    required this.modeLabel,
  });

  final Product product;
  final Color badgeColor;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.soft,
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Product Image / Placeholder
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.bluePastel,
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Icon(Icons.inventory_2_rounded, size: 36, color: badgeColor);
                },
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
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
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        modeLabel,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    Text(
                      'Stock: ${product.currentStock}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                Text(
                  'Barcode: ${product.barcode}',
                  style: AppTextStyles.cardSubtitle,
                ),
                Text(
                  'Brand: ${product.brand} | ${product.category}',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.statTitle),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.cardTitle),
            ],
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
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: onTap == null
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
