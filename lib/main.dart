import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/notifications/firebase_notification.dart';
import 'package:shop_app/provider/globalProvider.dart';
import 'package:shop_app/repository/repository.dart';
import 'package:shop_app/services/httpservices.dart';
import '../../../screens/home_page.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart'; // new
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart'; // new
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessage().initNotification();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Global_provider>(
            create: (context) => Global_provider()),
        Provider<HttpService>(
          create: (_) => HttpService(baseUrl: "https://fakestoreapi.com"),
        ),
        ProxyProvider<HttpService, MyRepository>(
            update: (_, httpService, __) =>
                MyRepository(httpService: httpService))
      ],
      child: Builder(
        builder: (context) {
          _initLanguage(context);
          return EasyLocalization(
            supportedLocales: const [Locale('en', 'US'), Locale('mn', 'MN')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en', 'US'),
            child: MyApp(),
          );
        },
      ),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomePage(),
      routes: [
        GoRoute(
          path: 'sign-in',
          builder: (context, state) {
            return SignInScreen(
              actions: [
                ForgotPasswordAction(((context, email) {
                  final uri = Uri(
                    path: '/sign-in/forgot-password',
                    queryParameters: <String, String?>{
                      'email': email,
                    },
                  );
                  context.push(uri.toString());
                })),
                AuthStateChangeAction(((context, state) {
                  final user = switch (state) {
                    SignedIn state => state.user,
                    UserCreated state => state.credential.user,
                    _ => null
                  };
                  if (user == null) {
                    return;
                  }
                  if (state is UserCreated) {
                    user.updateDisplayName(user.email!.split('@')[0]);
                  }
                  if (!user.emailVerified) {
                    user.sendEmailVerification();
                    const snackBar = SnackBar(
                        content: Text(
                            'Please check your email to verify your email address'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                  context.pushReplacement('/');
                })),
              ],
            );
          },
          routes: [
            GoRoute(
              path: 'forgot-password',
              builder: (context, state) {
                final arguments = state.uri.queryParameters;
                return ForgotPasswordScreen(
                  email: arguments['email'],
                  headerMaxExtent: 200,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) {
            return ProfileScreen(
              providers: const [],
              actions: [
                SignedOutAction((context) {
                  context.pushReplacement('/');
                }),
              ],
            );
          },
        ),
      ],
    ),
  ],
);
Future<void> _initLanguage(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedLanguage = prefs.getString('language');
  if (savedLanguage != null) {
    context.setLocale(
        Locale(savedLanguage.split('_')[0], savedLanguage.split('_')[1]));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        useMaterial3: true,
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: _router,
    );
  }
}
