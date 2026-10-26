import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'format.dart';
import 'models.dart';
import 'screens/entries_screen.dart';
import 'screens/hesap_screen.dart';
import 'screens/grafikler_screen.dart';
import 'widgets/logo_mark.dart';
import 'widgets/pill_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final store = BudgetStore();
  await store.load();
  runApp(ButceTakipApp(store: store));
}

class ButceTakipApp extends StatelessWidget {
  final BudgetStore store;
  const ButceTakipApp({super.key, required this.store});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: b,
      primary: dark ? AppColors.blue : AppColors.navy,
      surface: dark ? const Color(0xFF131A28) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF0A0E17) : const Color(0xFFF3F5F9),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: dark ? const Color(0xFF263149) : const Color(0xFFDDE3EC)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1A2334) : const Color(0xFFF3F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bütçe Takip',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(store: store),
    );
  }
}

class HomeShell extends StatefulWidget {
  final BudgetStore store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulama arka plandan dönünce zamanı gelen düzenli kayıtları ekle.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.store.refresh();
  }

  static const _items = [
    PillItem('Hesap', Icons.account_balance_wallet_outlined),
    PillItem('Gelirler', Icons.arrow_upward_rounded),
    PillItem('Giderler', Icons.arrow_downward_rounded),
    PillItem('Grafikler', Icons.bar_chart_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: store,
                      builder: (context, _) => IndexedStack(
                        index: _tab,
                        children: [
                          HesapScreen(store: store),
                          EntriesScreen(store: store, type: EntryType.gelir),
                          EntriesScreen(store: store, type: EntryType.gider),
                          GrafiklerScreen(store: store),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: 18 + MediaQuery.of(context).padding.bottom),
                  child: PillNav(
                    items: _items,
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const LogoMark(size: 40),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bütçe Takip',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              Text(
                longDate(DateTime.now()),
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
