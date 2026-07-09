import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/notification_transaction_model.dart';
import '../providers/finance_provider.dart';
import '../providers/notification_inbox_controller.dart';
import '../core/theme.dart';
import '../utils/formatters.dart';

class PaymentOptionsSheet extends ConsumerWidget {
  const PaymentOptionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Send Money',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Options Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentFormScreen(method: 'Scan QR'),
                    ),
                  );
                },
              ),
              _buildOption(
                context,
                icon: Icons.alternate_email_rounded,
                label: 'UPI ID',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentFormScreen(method: 'UPI ID'),
                    ),
                  );
                },
              ),
              _buildOption(
                context,
                icon: Icons.phone_iphone_rounded,
                label: 'Mobile No',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentFormScreen(method: 'Mobile Number'),
                    ),
                  );
                },
              ),
              _buildOption(
                context,
                icon: Icons.account_balance_rounded,
                label: 'Bank Transfer',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentFormScreen(method: 'Bank Transfer'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String method;
  const PaymentFormScreen({super.key, required this.method});

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscController = TextEditingController();

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.method == 'Scan QR') {
      _isScanning = true;
    }
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            // Scanning Target
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            
            // Pulse Scanning animation
            const Positioned(
              top: 150,
              child: Text(
                'Align QR code inside the frame',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),

            Positioned(
              bottom: 80,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Simulate Scan Success'),
                onPressed: () {
                  setState(() {
                    _receiverController.text = 'Rahul Sharma';
                    _isScanning = false;
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pay via ${widget.method}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receiver Inputs based on Method
              if (widget.method == 'Bank Transfer') ...[
                TextFormField(
                  controller: _receiverController,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                    hintText: 'e.g. Rahul Sharma',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter account holder name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    hintText: 'e.g. State Bank of India',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter bank name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    hintText: 'e.g. 30849204910',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter account number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ifscController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'IFSC Code',
                    hintText: 'e.g. SBIN0001234',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter IFSC code' : null,
                ),
              ] else ...[
                TextFormField(
                  controller: _receiverController,
                  decoration: InputDecoration(
                    labelText: widget.method == 'UPI ID'
                        ? 'UPI ID'
                        : widget.method == 'Mobile Number'
                            ? 'Mobile Number'
                            : 'Receiver Name',
                    hintText: widget.method == 'UPI ID'
                        ? 'e.g. rahul@upi'
                        : widget.method == 'Mobile Number'
                            ? 'e.g. 9876543210'
                            : 'e.g. Rahul Sharma',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'This field is required';
                    }
                    if (widget.method == 'Mobile Number' && val.length < 10) {
                      return 'Enter a valid mobile number';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: '0.00',
                  prefixText: '₹ ',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter payment amount';
                  final numVal = double.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'Enter a valid positive amount';
                  
                  // Check balance
                  final finance = ref.read(financeProvider);
                  if (numVal > finance.balance) {
                    return 'Insufficient balance (Current: ₹${finance.balance.toStringAsFixed(2)})';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Optional Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. Rent, Dinner, Coffee',
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _startPaymentProcess();
                    }
                  },
                  child: const Text('Pay Securely'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startPaymentProcess() {
    final amount = double.parse(_amountController.text);
    final receiver = _receiverController.text.trim();
    final note = _noteController.text.trim();

    // Show Fullscreen Processing screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingPaymentScreen(
          method: widget.method,
          receiver: receiver,
          amount: amount,
          note: note,
        ),
      ),
    );
  }
}

class ProcessingPaymentScreen extends ConsumerStatefulWidget {
  final String method;
  final String receiver;
  final double amount;
  final String note;

  const ProcessingPaymentScreen({
    super.key,
    required this.method,
    required this.receiver,
    required this.amount,
    required this.note,
  });

  @override
  ConsumerState<ProcessingPaymentScreen> createState() => _ProcessingPaymentScreenState();
}

class _ProcessingPaymentScreenState extends ConsumerState<ProcessingPaymentScreen> {
  String _statusText = 'Securing connection...';

  @override
  void initState() {
    super.initState();
    _runPaymentSimulation();
  }

  void _runPaymentSimulation() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _statusText = 'Verifying account details...');
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _statusText = 'Processing payment transaction...');

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Complete Transaction writing
    final finance = ref.read(financeProvider);
    final inbox = ref.read(notificationInboxControllerProvider.notifier);
    
    final upiRef = 'TXN${Random().nextInt(900000) + 100000}';
    final notes = widget.note.isNotEmpty ? widget.note : 'Demo payment via ${widget.method}';
    
    final tx = TransactionModel(
      userId: finance.userId,
      amount: widget.amount,
      merchant: widget.receiver,
      category: 'Others',
      type: 'debit',
      paymentMethod: widget.method,
      upiReference: upiRef,
      timestamp: DateTime.now(),
      notes: notes,
      source: 'Manual',
    );

    // Save transaction
    await finance.addTransaction(tx);

    // Generate simulated in-app notification
    final notificationMsg = 'You paid ${Formatters.currency(widget.amount)} to ${widget.receiver} via ${widget.method}.';
    final notificationId = 'nt_${DateTime.now().millisecondsSinceEpoch}';
    
    final notificationTx = NotificationTransaction(
      id: notificationId,
      userId: finance.userId,
      amount: widget.amount,
      merchant: widget.receiver,
      timestamp: DateTime.now(),
      type: 'debit',
      appName: widget.method,
      upiReference: upiRef,
      rawMessage: notificationMsg,
      status: 'confirmed',
      category: 'Others',
    );

    await inbox.saveNotificationDirect(notificationTx);

    // Navigate to Success screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            receiver: widget.receiver,
            amount: widget.amount,
            refId: upiRef,
            method: widget.method,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String receiver;
  final double amount;
  final String refId;
  final String method;

  const PaymentSuccessScreen({
    super.key,
    required this.receiver,
    required this.amount,
    required this.refId,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Pulsing checkmark
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Payment Successful',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              Formatters.currency(amount),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Card with details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight, width: 1.2),
              ),
              child: Column(
                children: [
                  _buildDetailRow('To', receiver),
                  const Divider(height: 20),
                  _buildDetailRow('Method', method),
                  const Divider(height: 20),
                  _buildDetailRow('Ref ID', refId),
                  const Divider(height: 20),
                  _buildDetailRow('Date & Time', "${Formatters.date(now)} ${Formatters.time(now)}"),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
