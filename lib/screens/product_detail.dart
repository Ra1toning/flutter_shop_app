// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/comment.dart';
import '../models/product_model.dart';
import '../provider/globalProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product_detail extends StatelessWidget {
  final ProductModel product;
  const Product_detail(this.product, {Key? key}) : super(key: key);

  Future<void> addComment(String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('comments').add({
        'productId': product.id,
        'userId': user.uid,
        'userName': user.displayName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Global_provider>(builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.network(
                      product.image!,
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      product.title!,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      product.description!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PRICE: \$${product.price}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // comment
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('comments')
                          .where('productId', isEqualTo: product.id)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text('Сэтгэгдэл алга');
                        }
                        return ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data!.docs
                              .map((DocumentSnapshot document) {
                            Map<String, dynamic>? data =
                                document.data() as Map<String, dynamic>?;
                            if (data == null) {
                              return SizedBox(); // Return an empty SizedBox if data is null
                            }
                            return ListTile(
                              title: Text(
                                data['userName'] ?? data['userId'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                data['message'] ?? '',
                                style: TextStyle(fontSize: 18),
                              ), // Use ?? '' to handle null values
                            );
                          }).toList(),
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SafeArea(
                child: Comment(addMessage: addComment),
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: FloatingActionButton(
            onPressed: () {
              provider.addCartItems(product, context);
            },
            child: const Icon(Icons.shopping_cart),
          ),
        ),
      );
    });
  }
}
