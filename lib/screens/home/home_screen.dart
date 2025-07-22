import 'package:flutter/material.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:save_your_car/widgets/actus_section.dart';
import 'package:save_your_car/widgets/home_header.dart';
import 'package:save_your_car/widgets/shorcut_grid.dart';
import 'package:save_your_car/widgets/title_section.dart';
import 'package:save_your_car/widgets/vehicle_list_horizontal.dart';
import 'package:save_your_car/widgets/search_bar.dart' as searchBar;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const HomeHeader(),

                // SearchBar positionnée à moitié dans le header - responsive positioning
                Positioned(
                  left: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                  right: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                  bottom: MediaQuery.of(context).size.height < 700 ? -24 : -28, // moitié de la hauteur + spacing
                  child: const searchBar.SearchBar(),
                ),
              ],
            ),
            
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 32 : 40),
                  VehicleListHorizontal(),
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 16 : 24),
                  ShortcutGrid(),
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 16 : 24),
                  SectionTitle(title: "Actus"),
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 8 : 12),
                  ActusSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
