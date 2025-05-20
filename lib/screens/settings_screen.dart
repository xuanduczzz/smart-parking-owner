import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale ?? const Locale('en');
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings'), style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('appearance'),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return SwitchListTile(
                    title: Text(tr('dark_mode'), style: GoogleFonts.montserrat(fontSize: 16)),
                    subtitle: Text(tr('dark_mode_desc'), style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey)),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr('language'),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(tr('select_language')),
                trailing: DropdownButton<Locale>(
                  value: currentLocale,
                  items: [
                    DropdownMenuItem(
                      value: const Locale('vi'),
                      child: Text(tr('vietnamese')),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text(tr('english')),
                    ),
                  ],
                  onChanged: (locale) {
                    if (locale != null) {
                      context.setLocale(locale);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 