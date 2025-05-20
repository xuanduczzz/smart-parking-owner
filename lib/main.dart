import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'repositories/auth_repository.dart';
import 'blocs/auth/auth_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'blocs/parking_lot/parking_lot_bloc.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home/home_screen.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/voucher/voucher_bloc.dart';
import 'blocs/qr/qr_bloc.dart';
import 'repositories/qr_repository.dart';
import 'blocs/profile/profile_bloc.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/settings_screen.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      child: MyRootApp(prefs: prefs),
    ),
  );
}

class MyRootApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyRootApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(AuthRepository())..add(CheckAuthStatusEvent()),
          ),
          BlocProvider(
            create: (_) => ParkingLotBloc(CloudinaryPublic('dqnbclzi5', 'avatar_img', cache: false)),
          ),
          BlocProvider(
            create: (_) => VoucherBloc(),
          ),
          BlocProvider(
            create: (context) => QRBloc(
              QRRepository(),
            ),
          ),
          BlocProvider(
            create: (_) => ProfileBloc(),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              title: 'Parking App',
              theme: themeProvider.currentTheme,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    return const HomeScreen();
                  } else if (state is Unauthenticated) {
                    return const LoginScreen();
                  } else {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
