import 'package:firebase_core/firebase_core.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/routes.dart';
import 'package:planejamento_financeiro/network/session_events.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/screens/splash.dart';
import 'package:planejamento_financeiro/theme/theme.dart';

import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();

  // Refresh recusado pela API: volta para o login com um aviso.
  onSessionExpiredHandler = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      fadeRoute((context) => const LoginScreen()),
      (route) => false,
    );
    messengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Sua sessão expirou. Entre de novo.')),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      title: 'Planejamento financeiro',
      theme: AppTheme.defaultTheme,
      home: const SplashScreen(),
      // home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        FormBuilderLocalizations.delegate,
      ],
      supportedLocales: [Locale("pt", "BR")],
    );
  }
}
