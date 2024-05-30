import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/services/httpservices.dart';
import 'package:shop_app/models/users.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class MyRepository {
  final HttpService httpService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MyRepository({required this.httpService});
  Future<List<ProductModel>?> fetchProductData() async {
    try {
      dynamic jsonData = await httpService.getData('products', null);
      List<ProductModel> data = ProductModel.fromList(jsonData);
      return data;
    } catch (e) {
      throw Exception('Failed to load data');
    }
  }

  Future<List<ProductModel>> fetchCartProducts() async {
    List<ProductModel> cartProducts = [];

    try {
      if (_auth.currentUser != null) {
        final userId = _auth.currentUser!.uid;
        final QuerySnapshot cartSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .get();

        cartProducts = cartSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ProductModel.fromJson(data);
        }).toList();
      }
    } catch (e) {
      print('Error fetching cart products: $e');
    }

    return cartProducts;
  }

  Future<List<ProductModel>> fetchFavoriteProducts() async {
    List<ProductModel> favoriteProducts = [];

    try {
      if (_auth.currentUser != null) {
        final userId = _auth.currentUser!.uid;
        final QuerySnapshot favoriteSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorite')
            .get();

        favoriteProducts = favoriteSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ProductModel.fromJson(data);
        }).toList();
      }
    } catch (e) {
      print('Error fetching favorite products: $e');
    }

    return favoriteProducts;
  }

  Future<List<UserModel>> fetchUserDatafromLocal() async {
    String res = await rootBundle.loadString("assets/users.json");
    List<UserModel> data = UserModel.fromList(jsonDecode(res));
    return data;
  }

  Future<bool> submitCart(
      int userId, List<Map<String, dynamic>> products) async {
    final Map<String, dynamic> requestData = {
      "userId": userId,
      "products": products,
    };

    try {
      final response =
          await httpService.postData('userCarts', null, requestData);

      print('Request data: $requestData');
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
