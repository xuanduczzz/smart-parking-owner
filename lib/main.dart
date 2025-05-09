import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kiểm tra xem Firebase đã được khởi tạo chưa
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(AuthRepository())..add(CheckAuthStatusEvent()),
        ),
        BlocProvider(
          create: (_) => ParkingLotBloc(CloudinaryPublic('dqnbclzi5', 'avatar_img', cache: false)),
        ),
      ],
      child: MaterialApp(
        title: 'Parking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.montserratTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.blue),
          ),
          iconTheme: const IconThemeData(color: Colors.blue),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Colors.blue,
            contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            behavior: SnackBarBehavior.floating,
          ),
        ),
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
      ),
    );
  }
}
