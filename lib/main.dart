// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brigade Rouge 2001',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const OrderForm(),
    );
  }
}

class OrderForm extends StatefulWidget {
  const OrderForm({super.key});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Map<String, TextEditingController> _sizeControllers = {
    'S': TextEditingController(text: '0'),
    'M': TextEditingController(text: '0'),
    'L': TextEditingController(text: '0'),
    'XL': TextEditingController(text: '0'),
    'XXL': TextEditingController(text: '0'),
    'XXXL': TextEditingController(text: '0'),
  };
  bool _isSubmitted = false;

  int get totalQuantity {
    int total = 0;
    for (var controller in _sizeControllers.values) {
      total += int.tryParse(controller.text) ?? 0;
    }
    return total;
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        Map<String, int> sizes = {};
        for (var entry in _sizeControllers.entries) {
          sizes[entry.key] = int.parse(entry.value.text);
        }

        // Create a document with the customer name as the ID
        String documentId =
            _nameController.text.trim().replaceAll(' ', '_').toLowerCase();
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(documentId)
            .set({
          'name': _nameController.text,
          'sizes': sizes,
          'totalQuantity': totalQuantity,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isSubmitted = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting order: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildConfirmationPage();
    }
    return _buildOrderForm();
  }

  Widget _buildOrderForm() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produit 2025'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                "assets/banner.png",
                fit: BoxFit.fitWidth,
                height: MediaQuery.of(context).size.height * 0.2,
                width: MediaQuery.of(context).size.width * 0.99,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom Section',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nom Section';
                  }
                  return null;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Size Quantities:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total: $totalQuantity',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _sizeControllers.length,
                  itemBuilder: (context, index) {
                    String size = _sizeControllers.keys.elementAt(index);
                    var controller = _sizeControllers[size]!;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              'Size $size:',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                int currentValue =
                                    int.tryParse(controller.text) ?? 0;
                                if (currentValue > 0) {
                                  setState(() {
                                    controller.text =
                                        (currentValue - 1).toString();
                                  });
                                }
                              },
                            ),
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 8),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                int currentValue =
                                    int.tryParse(controller.text) ?? 0;
                                setState(() {
                                  controller.text =
                                      (currentValue + 1).toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Submit Order',
                      style: TextStyle(fontSize: 18, color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              "assets/banner.png",
              fit: BoxFit.fitWidth,
              height: MediaQuery.of(context).size.height * 0.2,
              width: MediaQuery.of(context).size.width * 0.99,
            ),
            const Text(
              'Order Submitted Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Customer Name: ${_nameController.text}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              'Order Details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...(_sizeControllers.entries.map((entry) {
              int quantity = int.tryParse(entry.value.text) ?? 0;
              if (quantity > 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Size ${entry.key}: ${entry.value.text}',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }
              return const SizedBox.shrink();
            })),
            const SizedBox(height: 20),
            Text(
              'Total Quantity: $totalQuantity',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
/*            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderForm())
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'New Order',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _sizeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
