import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shop_app/firebase_options.dart';
import 'package:shop_app/models/product_model.dart';
import 'package:shop_app/models/users.dart';
import 'package:shop_app/models/guest_book_message.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'dart:async';

class Global_provider extends ChangeNotifier {
  List<ProductModel> products = [];
  List<ProductModel> cartItems = [];
  List<ProductModel> favoriteItems = [];
  List<UserModel> users = [];
  int currentIdx = 0;
  UserModel? _currentUser;
  int? _localUserId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _guestBookSubscription;
  List<GuestBookMessage> _guestBookMessages = [];
  List<GuestBookMessage> get guestBookMessages => _guestBookMessages;

  Global_provider() {
    init();
  }
  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _guestBookSubscription = FirebaseFirestore.instance
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          _guestBookMessages = [];
          for (final document in snapshot.docs) {
            _guestBookMessages.add(
              GuestBookMessage(
                name: document.data()['name'] as String,
                message: document.data()['text'] as String,
              ),
            );
          }
          notifyListeners();
        });
      } else {
        _loggedIn = false;
        _guestBookMessages = [];
        _guestBookSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  void setProducts(List<ProductModel> data) {
    products = data;
    notifyListeners();
  }

  void setCartItems(List<ProductModel> data) {
    cartItems = data;
    notifyListeners();
  }

  void setUsers(List<UserModel> item) {
    users = item;
    notifyListeners();
  }

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  UserModel? get currentUser => _currentUser;

  Future<void> addCartItems(ProductModel item, BuildContext context) async {
    try {
      if (_auth.currentUser != null) {
        final userId = _auth.currentUser!.uid;
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(item.id.toString());
        final docSnapShot = await docRef.get();
        if (docSnapShot.exists) {
          cartItems.firstWhere((element) => element.id == item.id).count++;
          await docRef.update({
            'count':
                cartItems.firstWhere((element) => element.id == item.id).count
          });
        } else {
          cartItems.add(item);
          await docRef.set(item.toJson());
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бараа амжилттай нэмэгдлээ'),
          ),
        );
        notifyListeners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Та эхлээд нэвтрэх шаардлагатай'),
          ),
        );
      }
    } catch (e) {
      print('Error adding cart items: $e');
    }
  }

  int getCurrentUserId() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return userId != null ? int.parse(userId) : 0;
  }

  Future<void> addfavItems(ProductModel item, BuildContext context) async {
    try {
      if (_auth.currentUser != null) {
        final userId = _auth.currentUser!.uid;
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('favorite')
            .doc(item.id.toString());
        final docSnapShot = await docRef.get();
        if (docSnapShot.exists) {
          // The item is already in the favorites, no need to add it again
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Бараа аль хэдийн дуртай бараануудын жагсаалтад байна'),
            ),
          );
        } else {
          favoriteItems.add(item);
          await docRef.set(item.toJson());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Бараа амжилттай нэмэгдлээ'),
            ),
          );
        }
        notifyListeners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Та эхлээд нэвтрэх шаардлагатай'),
          ),
        );
      }
    } catch (e) {
      print('Error adding favorite items: $e');
    }
  }

  Future<DocumentReference> addMessageToGuestBook(String message) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }

    return FirebaseFirestore.instance
        .collection('guestbook')
        .add(<String, dynamic>{
      'text': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'name': FirebaseAuth.instance.currentUser!.displayName,
      'userId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  void clearCart() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        final userId = auth.currentUser!.uid;
        final CollectionReference cartCollection =
            _firestore.collection('users').doc(userId).collection('cart');

        // Delete each document from the cart collection
        final cartItemsSnapshot = await cartCollection.get();
        for (final doc in cartItemsSnapshot.docs) {
          await doc.reference.delete();
        }
      }

      // Clear the local cartItems list
      cartItems.clear();

      // Notify listeners to update the UI
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  void removeFavorite(int index) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final favoriteItem = favoriteItems[index];
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('favorite')
            .doc(favoriteItem.id.toString());

        // Delete the document from Firestore
        await docRef.delete();

        // Remove the item from the local list
        favoriteItems.removeAt(index);

        // Notify listeners to update the UI
        notifyListeners();
      }
    } catch (e) {
      print('Error removing favorite item: $e');
    }
  }

  void changeCurrentIdx(int idx) {
    currentIdx = idx;
    notifyListeners();
  }

  Future<void> incrementQuantity(int index) async {
    if (index < 0 || index >= cartItems.length) {
      print('Invalid index: $index');
      return;
    }
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // Increment the local count
        cartItems[index].count++;

        // Update Firestore with the new count
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(cartItems[index].id.toString());

        await docRef.update({'count': cartItems[index].count});

        // Notify listeners to update the UI
        notifyListeners();
      }
    } catch (e) {
      print('Error incrementing quantity: $e');
    }
  }

  Future<void> decreaseQuantity(int index) async {
    if (index < 0 || index >= cartItems.length) {
      print('Invalid index: $index');
      return;
    }
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        if (cartItems[index].count > 1) {
          // Decrease the local count
          cartItems[index].count--;

          // Update Firestore with the new count
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('cart')
              .doc(cartItems[index].id.toString());

          await docRef.update({'count': cartItems[index].count});
        } else {
          // Remove the item from the cart if count is 1
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('cart')
              .doc(cartItems[index].id.toString());

          await docRef.delete();
          cartItems.removeAt(index);
        }

        // Notify listeners to update the UI
        notifyListeners();
      }
    } catch (e) {
      print('Error decrementing quantity: $e');
    }
  }

  Future<void> saveToken(String token) async {
    final storage = FlutterSecureStorage();
    await storage.write(key: 'token', value: token);
  }

  void setLocalUserId(int? userId) {
    _localUserId = userId;
    notifyListeners();
  }

  int? getLocalUserId() {
    return _localUserId;
  }

  Future<String?> getToken() async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: 'token');
  }
}
