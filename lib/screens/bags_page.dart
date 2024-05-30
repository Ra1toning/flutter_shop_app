import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:shop_app/repository/repository.dart';
import 'package:easy_localization/easy_localization.dart';

class BagsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductModel>>(
      future:
          Provider.of<MyRepository>(context, listen: false).fetchCartProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          List<ProductModel> cartItems = snapshot.data!;
          Provider.of<Global_provider>(context, listen: false)
              .setCartItems(cartItems);

          return Consumer<Global_provider>(
            builder: (context, globalProvider, child) {
              final cartItems = globalProvider.cartItems;
              double total = cartItems.fold(
                0.0,
                (sum, item) => sum + (item.price ?? 0) * item.count,
              );

              return Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: const Color.fromARGB(223, 253, 253, 253),
                  title: Text(
                    "cart".tr(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(223, 37, 37, 37),
                    ),
                  ),
                ),
                body: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var cartItem = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 150,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: cartItem.image != null
                                    ? Image.network(
                                        cartItem.image!,
                                        width: 50,
                                        height: 50,
                                      )
                                    : const Icon(Icons.image_not_supported,
                                        size: 50),
                                title: Text(
                                  cartItem.title ?? 'No title',
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            globalProvider
                                                .decreaseQuantity(index);
                                          },
                                        ),
                                        Text('${cartItem.count}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            globalProvider
                                                .incrementQuantity(index);
                                          },
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '\$${(cartItem.price ?? 0).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Нийт: \$${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final globalProvider = Provider.of<Global_provider>(
                              context,
                              listen: false);
                          final auth = FirebaseAuth.instance;

                          if (auth.currentUser != null) {
                            final userId = auth.currentUser!.uid;
                            final cartItems = globalProvider.cartItems;

                            // Prepare data for purchase
                            final List<Map<String, dynamic>>
                                purchasedItemsData = cartItems.map((item) {
                              return {
                                'productId': item.id,
                                'productName': item.title,
                                'quantity': item.count,
                                'price': item.price,
                              };
                            }).toList();

                            final FirebaseFirestore firestore =
                                FirebaseFirestore.instance;
                            final CollectionReference boughtCollection =
                                firestore.collection('Bought');
                            final Map<String, dynamic> purchaseData = {
                              'userId': userId,
                              'items': purchasedItemsData,
                            };
                            await boughtCollection.add(purchaseData);

                            globalProvider.clearCart();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Худалдан авалт амжилттай!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Нэвтэрж орсноор худалдан авалт хийх боломжтой'),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'buy'.tr(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Center(
            child: Text('No data available'),
          );
        }
      },
    );
  }
}
