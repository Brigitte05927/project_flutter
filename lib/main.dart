import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remplacez ces valeurs par vos clés Supabase
  const supabaseUrl = 'https://zdeqllmnocmddaxmtaen.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkZXFsbG1ub2NtZGRheG10YWVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4MjQwMjUsImV4cCI6MjA3NTQwMDAyNX0._gV2nTPc7E2SkmRfB1cOQAM0pWPH6JmQKpmY8x2Pw6Y';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ComplaintApp());
}

class ComplaintApp extends StatelessWidget {
  const ComplaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistant Juridique & Analyse de Plaintes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final session = snapshot.data?.session;
        return session != null ? HomeScreen() : LoginScreen();
      },
    );
  }
}