import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/theme/responsive_helper.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:save_your_car/models/conseil_category.dart';

class ConseilsScreen extends StatefulWidget {
  const ConseilsScreen({super.key});

  @override
  State<ConseilsScreen> createState() => _ConseilsScreenState();
}

class _ConseilsScreenState extends State<ConseilsScreen> {
  final List<ConseilCategory> categories = [
    // Top Berlines Hybrides
    ConseilCategory(
      id: 'berlines_hybrides',
      title: 'Top Berlines Hybrides',
      subtitle: 'Les berlines hybrides les plus fiables (2015-2024)',
      icon: Icons.directions_car,
      color: Colors.blue,
      items: [
        'Toyota Corolla Hybride (2019-2024) : Note 5/5 - Ultra fiable, consommation basse en ville',
        'Lexus ES 300h (2019-2024) : Note 5/5 - Finition premium, confort exemplaire',
        'Honda Civic Hybride (2022-2024) : Note 4/5 - Moteur efficient, conduite agréable',
        'Hyundai Ioniq Hybrid (2016-2022) : Note 4/5 - Excellent rapport qualité/prix, faible conso',
        'Kia Niro PHEV (2019-2023) : Note 4/5 - Économique, bonne garantie',
        'Renault Mégane E-Tech (2020-2024) : Note 4/5 - Technologie moderne, confort appréciable',
        'BMW Série 3 330e (2019-2024) : Note 4/5 - Très bon dynamisme, qualité BMW',
        'Peugeot 508 Hybrid (2020-2024) : Note 4/5 - Design soigné, motorisation sobre',
        'Mercedes Classe C 300e (2021-2024) : Note 4/5 - Excellente autonomie électrique',
        'Volvo S60 Recharge (2020-2024) : Note 4/5 - Puissance élevée, confort de haut niveau',
      ],
    ),
    
    // Top Berlines Essence
    ConseilCategory(
      id: 'berlines_essence',
      title: 'Top Berlines Essence',
      subtitle: 'Les berlines essence les plus fiables (2015-2024)',
      icon: Icons.local_gas_station,
      color: Colors.amber,
      items: [
        'Toyota Corolla (2019-2024) : Note 5/5 - Ultra fiable, consommation basse',
        'Honda Civic X/XI (2017-2024) : Note 5/5 - Moteur atmosphérique fiable, très faible consommation',
        'Volkswagen Golf VII/VIII (2015-2024) : Note 4/5 - Très bon compromis routier, motorisation fiable',
        'BMW Série 1 F20/F40 (2015-2024) : Note 4/5 - Très bon agrément de conduite, finitions solides',
        'Audi A3 8V/8Y (2015-2024) : Note 4/5 - Qualité perçue premium, polyvalente',
        'Mercedes Classe A (2015-2024) : Note 4/5 - Technologie avancée, fiabilité correcte',
        'Skoda Octavia III/IV (2015-2024) : Note 4/5 - Très bonne habitabilité, bonne fiabilité générale',
        'Mazda Mazda 3 (2015-2024) : Note 4/5 - Agrément dynamique, fiabilité moteur essence',
        'Hyundai i30 (2015-2024) : Note 4/5 - Entretien accessible, moteur sobre',
        'Kia Ceed (2015-2024) : Note 4/5 - Bon compromis prix/équipement, conduite agréable',
      ],
    ),

    // Top Berlines Diesel
    ConseilCategory(
      id: 'berlines_diesel',
      title: 'Top Berlines Diesel',
      subtitle: 'Les berlines diesel les plus fiables (2015-2024)',
      icon: Icons.directions_car_filled,
      color: Colors.blueGrey,
      items: [
        'Volkswagen Golf VII/VIII (2015-2024) : Note 4/5 - Excellente finition, moteur TDI robuste (post-2016)',
        'BMW Série 1 F20/F40 (2015-2024) : Note 4/5 - Agrément de conduite premium, moteur efficace',
        'Audi A3 8V/8Y (2015-2024) : Note 4/5 - Tenue de route sûre, motorisation efficace',
        'Mercedes Classe A (2015-2024) : Note 4/5 - Bon confort, finition correcte',
        'Skoda Octavia III/IV (2015-2024) : Note 4/5 - Volume intérieur généreux, consommation maîtrisée',
        'Toyota Avensis (2015-2018) : Note 4/5 - Fiabilité correcte, bon confort',
        'Honda Civic IX/X (2015-2020) : Note 4/5 - Très bonne fiabilité, moteur sobre',
        'Seat Leon III/IV (2015-2024) : Note 4/5 - Très bon comportement, design moderne',
        'Opel Astra K/L (2016-2024) : Note 4/5 - Châssis équilibré, bon agrément routier',
        'Volvo S60 (2015-2022) : Note 4/5 - Confort de conduite élevé, moteur fiable',
      ],
    ),

    // Top 4x4 véritables
    ConseilCategory(
      id: 'vrais_4x4',
      title: 'Top Véritables 4x4',
      subtitle: 'Les 4x4 les plus robustes (2015-2024)',
      icon: Icons.terrain,
      color: Colors.green,
      items: [
        'Toyota Land Cruiser (2015-2024) : Note 5/5 - Robustesse reconnue, franchissement exceptionnel',
        'Suzuki Jimny (2018-2024) : Note 5/5 - Compact et léger, très agile en nature',
        'Mercedes Classe G (2015-2024) : Note 5/5 - Icône de robustesse, haut de gamme total',
        'Lexus RX 450h (2015-2024) : Note 5/5 - Fiabilité Lexus, confort haut de gamme',
        'Jeep Wrangler (2015-2024) : Note 4/5 - Style unique, bonnes capacités tout-terrain',
        'Land Rover Defender (2020-2024) : Note 4/5 - Très moderne et capable, excellent en off-road',
        'Mitsubishi Pajero (2015-2020) : Note 4/5 - Très fiable en milieu difficile, réparations simples',
        'Dacia Duster 4x4 (2015-2024) : Note 4/5 - Prix très abordable, bonne efficacité en 4x4',
        'Ford Ranger Raptor (2019-2024) : Note 4/5 - Performant et fun, bonnes aptitudes terrain',
        'Volkswagen Amarok (2016-2022) : Note 4/5 - Puissant et polyvalent, bonne motricité',
      ],
    ),

    // Top SUV Hybrides
    ConseilCategory(
      id: 'suv_hybrides',
      title: 'Top SUV Hybrides',
      subtitle: 'Les SUV hybrides les plus fiables (2015-2024)',
      icon: Icons.eco,
      color: Colors.teal,
      items: [
        'Toyota C-HR Hybride (2016-2024) : Note 5/5 - Fiabilité remarquable, conso basse en ville',
        'Lexus UX 250h (2019-2024) : Note 5/5 - Finition premium, très silencieux',
        'Honda HR-V Hybride (2021-2024) : Note 4/5 - Très bonne finition, silencieux en ville',
        'Hyundai Tucson Hybrid (2021-2024) : Note 4/5 - Design moderne, bonne autonomie hybride',
        'Kia Niro HEV (2016-2024) : Note 4/5 - Conso très basse, garantie longue durée',
        'Renault Austral E-Tech (2022-2024) : Note 4/5 - Très technologique, bon comportement routier',
        'Ford Kuga Hybride (2020-2024) : Note 4/5 - Équipement complet, conduite souple',
        'Suzuki Across (2020-2024) : Note 4/5 - Partage techno Toyota, très fiable',
        'Mitsubishi Outlander PHEV (2015-2023) : Note 4/5 - Bon rapport qualité/équipement, 4x4 utile',
        'Mazda CX-60 PHEV (2022-2024) : Note 4/5 - Très confortable, puissant et hybride',
      ],
    ),

    // Top Citadines Hybrides
    ConseilCategory(
      id: 'citadines_hybrides',
      title: 'Top Citadines Hybrides',
      subtitle: 'Les citadines hybrides les plus économiques (2015-2024)',
      icon: Icons.eco,
      color: Colors.lightGreen,
      items: [
        'Toyota Yaris Hybride (2015-2024) : Note 5/5 - Très grande fiabilité, consommation très faible',
        'Honda Jazz Hybride (2020-2024) : Note 5/5 - Silencieuse et fiable, très économique en ville',
        'Lexus CT 200h (2015-2020) : Note 5/5 - Très fiable, confort Lexus',
        'Renault Clio E-Tech (2020-2024) : Note 4/5 - Agréable à conduire, bonne gestion électrique',
        'Hyundai i20 Hybrid (2020-2024) : Note 4/5 - Bon compromis techno/prix, bonne finition intérieure',
        'Kia Rio Hybrid (2020-2023) : Note 4/5 - Bonne garantie constructeur, moteur agréable en ville',
        'Suzuki Swift Hybrid (2020-2024) : Note 4/5 - Agrément de conduite léger, prix compétitif',
        'Fiat 500 Hybrid (2020-2024) : Note 4/5 - Look sympa, consommation réduite',
        'Ford Puma mHEV (2020-2024) : Note 3/5 - Design attractif, bon équipement techno',
        'Audi A1 Citycarver MHEV (2020-2022) : Note 3/5 - Style premium, bonne tenue de route',
      ],
    ),

    // Top SUV Essence
    ConseilCategory(
      id: 'suv_essence',
      title: 'Top SUV Essence',
      subtitle: 'Les SUV essence les plus fiables (2015-2024)',
      icon: Icons.local_gas_station,
      color: Colors.orange,
      items: [
        'Toyota C-HR (2016-2024) : Note 5/5 - Très fiable, hybride disponible aussi',
        'Peugeot 2008 (2015-2024) : Note 4/5 - Très bon agrément de conduite, bonne finition intérieure',
        'Volkswagen T-Roc (2017-2024) : Note 4/5 - Qualité perçue solide, comportement routier équilibré',
        'Dacia Duster (2015-2024) : Note 4/5 - Rapport qualité/prix imbattable, entretien simple',
        'Citroën C3 Aircross (2017-2024) : Note 4/5 - Position de conduite agréable, équipements corrects',
        'Hyundai Kona (2017-2024) : Note 4/5 - Polyvalent et moderne, bonne dotation technologique',
        'Kia Stonic (2018-2024) : Note 4/5 - Look dynamique, consommation contenue',
        'Ford Puma (2020-2024) : Note 4/5 - Conduite agréable, bonne modularité',
        'Seat Arona (2018-2024) : Note 4/5 - Style affirmé, agréable à conduire',
        'Skoda Kamiq (2019-2024) : Note 4/5 - Très bonne habitabilité, équipement complet',
      ],
    ),

    // Top SUV Diesel
    ConseilCategory(
      id: 'suv_diesel',
      title: 'Top SUV Diesel',
      subtitle: 'Les SUV diesel les plus fiables (2015-2024)',
      icon: Icons.directions_car_filled,
      color: Colors.brown,
      items: [
        'Peugeot 3008 (2016-2024) : Note 4/5 - Bon équilibre confort/performances, consommation maîtrisée',
        'Volkswagen Tiguan (2016-2024) : Note 4/5 - Fiabilité générale correcte, bonne tenue de route',
        'Dacia Duster (2015-2024) : Note 4/5 - Rapport qualité/prix imbattable, entretien simple et accessible',
        'Citroën C5 Aircross (2018-2024) : Note 4/5 - Très bon confort de suspension, espace intérieur généreux',
        'Hyundai Tucson (2015-2024) : Note 4/5 - Fiabilité solide, agrément de conduite',
        'Kia Sportage (2015-2024) : Note 4/5 - Bonne garantie constructeur, agréable en famille',
        'Seat Ateca (2016-2024) : Note 4/5 - Bonne assise de conduite, tenue de route sécurisante',
        'Skoda Karoq (2017-2024) : Note 4/5 - Très bon espace arrière, équipement riche',
        'Mazda CX-5 (2015-2023) : Note 4/5 - Excellent confort, motorisation sobre',
        'BMW X1 (2015-2024) : Note 4/5 - Très bon moteur diesel, finition soignée',
      ],
    ),

    // Top Citadines Essence
    ConseilCategory(
      id: 'citadines_essence',
      title: 'Top Citadines Essence',
      subtitle: 'Les citadines essence les plus fiables (2015-2024)',
      icon: Icons.local_gas_station,
      color: Colors.red,
      items: [
        'Toyota Yaris (2015-2024) : Note 5/5 - Fiabilité moteur exceptionnelle, entretien économique',
        'Honda Jazz (2015-2024) : Note 5/5 - Très fiable, entretien économique',
        'Suzuki Swift (2015-2024) : Note 5/5 - Très fiable, conduite agréable',
        'Peugeot 208 (2015-2024) : Note 4/5 - Bon comportement routier, consommation maîtrisée',
        'Volkswagen Polo VI (2017-2024) : Note 4/5 - Finition solide, moteurs TSI fiables',
        'Hyundai i10 (2015-2024) : Note 4/5 - Parfaite en ville, fiabilité mécanique',
        'Kia Picanto (2017-2024) : Note 4/5 - Entretien facile, bon rapport prix/équipement',
        'Fiat 500 (2015-2024) : Note 4/5 - Design iconique, taille idéale en ville',
        'Dacia Sandero II/III (2016-2024) : Note 4/5 - Bon rapport qualité/prix, bonne fiabilité',
        'Opel Corsa E/F (2015-2024) : Note 4/5 - Amélioration notable depuis 2020, agréable à conduire',
      ],
    ),

    // Top Citadines Diesel
    ConseilCategory(
      id: 'citadines_diesel',
      title: 'Top Citadines Diesel',
      subtitle: 'Les citadines diesel les plus fiables (2015-2024)',
      icon: Icons.directions_car_filled,
      color: Colors.indigo,
      items: [
        'Toyota Yaris (D-4D) (2015-2020) : Note 5/5 - Très fiable, faible consommation',
        'Peugeot 208 (2015-2022) : Note 4/5 - Moteur BlueHDi sobre, bonne tenue de route',
        'Volkswagen Polo VI (2017-2023) : Note 4/5 - Très bonne finition, moteur TDI fiable post-2018',
        'Citroën C3 III (2016-2022) : Note 4/5 - Confort satisfaisant, moteur HDi éprouvé',
        'Dacia Sandero II/III (2015-2023) : Note 4/5 - Très bon rapport qualité/prix, moteur fiable',
        'Skoda Fabia III/IV (2015-2024) : Note 4/5 - Confort correct, bonne fiabilité post-2018',
        'Seat Ibiza V (2017-2022) : Note 4/5 - Bon équilibre général, moteur TDI solide',
        'Mini Mini III (2015-2023) : Note 4/5 - Très bonne finition, bonne tenue de route',
        'Mazda Mazda 2 (2015-2020) : Note 4/5 - Moteur sobre, conduite agréable',
        'Honda Jazz (2015-2020) : Note 4/5 - Bonne fiabilité, faible consommation',
      ],
    ),

    // Top Utilitaires & Fourgonnettes
    ConseilCategory(
      id: 'utilitaires',
      title: 'Top Utilitaires & Fourgonnettes',
      subtitle: 'Les utilitaires les plus durables (2015-2024)',
      icon: Icons.local_shipping,
      color: Colors.orange,
      items: [
        'Renault Kangoo (2015-2024) : Note 4/5 - Fiabilité reconnue, facilité d\'entretien',
        'Peugeot Partner (2015-2024) : Note 4/5 - Bon confort, polyvalent',
        'Citroën Berlingo (2015-2024) : Note 4/5 - Pratique en ville, modularité appréciée',
        'Volkswagen Caddy (2015-2024) : Note 4/5 - Qualité VW, bonne longévité',
        'Opel Combo (2015-2024) : Note 4/5 - Base PSA efficace, bonne tenue de route',
        'Toyota Proace City (2020-2024) : Note 4/5 - Agrément de conduite, bonne modularité',
        'Renault Trafic (2015-2024) : Note 4/5 - Excellente polyvalence, bonne tenue de route',
        'Peugeot Expert (2015-2024) : Note 4/5 - Très bon compromis, bonne modularité',
        'Citroën Jumpy (2015-2024) : Note 4/5 - Compact et fonctionnel, nombreuses versions',
        'Ford Transit Custom (2015-2024) : Note 4/5 - Référence du segment, bonne tenue de route',
      ],
    ),

    // Top Monospaces
    ConseilCategory(
      id: 'monospaces',
      title: 'Top Monospaces',
      subtitle: 'Les monospaces les plus familiaux (2015-2024)',
      icon: Icons.groups,
      color: Colors.deepPurple,
      items: [
        'Honda Jazz (2015-2024) : Note 5/5 - Ultra fiable, consommation basse',
        'Renault Scénic IV (2016-2022) : Note 4/5 - Bonne modularité, confort familial',
        'Volkswagen Touran (2015-2024) : Note 4/5 - Très bon compromis famille, bonne finition',
        'Ford S-Max (2015-2024) : Note 4/5 - Conduite agréable, grand volume de coffre',
        'Toyota Verso (2015-2018) : Note 4/5 - Compact et pratique, fiable',
        'Dacia Lodgy (2015-2021) : Note 4/5 - Prix imbattable, espace correct',
        'BMW Série 2 Active Tourer (2015-2024) : Note 4/5 - Qualité premium BMW, moteurs sobres',
        'Mercedes Classe B (2015-2024) : Note 4/5 - Confort premium, sécurité renforcée',
        'Seat Alhambra (2015-2020) : Note 4/5 - Bonne tenue de route, coffre généreux',
        'Hyundai ix20 (2015-2020) : Note 4/5 - Format idéal en ville, fiabilité correcte',
      ],
    ),

    // Classement Fiabilité par Marques
    ConseilCategory(
      id: 'fiabilite_marques',
      title: 'Fiabilité par Marques',
      subtitle: 'Classement général de fiabilité (2015-2024)',
      icon: Icons.star,
      color: Colors.amber,
      items: [
        '1. Toyota - Note : 4.8/5 - Excellente fiabilité sur l\'ensemble des gammes',
        '2. Lexus - Note : 4.7/5 - Très haut de gamme et robuste',
        '3. Honda - Note : 4.5/5 - Mécanique simple et durable',
        '4. Mazda - Note : 4.4/5 - Bon équilibre entre technologie et durabilité',
        '5. Hyundai - Note : 4.3/5 - Amélioration continue, fiabilité solide',
        '6. Kia - Note : 4.2/5 - Produits bien conçus, fiabilité stable',
        '7. BMW - Note : 4.1/5 - Qualité premium mais coûts d\'entretien élevés',
        '8. Audi - Note : 4.0/5 - Technologie avancée mais parfois complexe',
        '9. Mercedes - Note : 4.0/5 - Fiable globalement, entretiens coûteux',
        '10. Peugeot - Note : 3.9/5 - Bonne tenue générale, problèmes moteurs PureTech',
      ],
    ),

    // Coûts d'Entretien par Marque
    ConseilCategory(
      id: 'entretien_marques',
      title: 'Coûts d\'Entretien par Marque',
      subtitle: 'Classement des coûts d\'entretien annuels (2015-2024)',
      icon: Icons.build,
      color: Colors.purple,
      items: [
        '1. Dacia - 400€/an - Très abordable, pièces simples et robustes',
        '2. Toyota - 450€/an - Fiabilité + pièces accessibles = entretien modéré',
        '3. Kia - 460€/an - Bonne garantie, pièces peu chères',
        '4. Hyundai - 470€/an - Bon rapport coût/performance, peu de pannes lourdes',
        '5. Renault - 480€/an - Large réseau, prix maîtrisé',
        '6. Peugeot - 500€/an - Tarifs corrects mais certains moteurs sensibles',
        '7. Citroën - 500€/an - Même base que Peugeot, coûts similaires',
        '8. Mazda - 520€/an - Fiabilité bonne, entretien accessible',
        '9. Volkswagen - 550€/an - Réseau vaste mais pièces chères',
        '10. BMW - 700€/an - Premium = coût élevé malgré bonne fiabilité',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return MainScaffold(
      currentIndex: -1,
      child: Scaffold(
        backgroundColor: FigmaColors.neutral00,
        appBar: AppBar(
          backgroundColor: FigmaColors.neutral100,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Nos Conseils',
            style: textStyle.headingSBold.copyWith(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Guides de Fiabilité Automobile',
                style: textStyle.textLBold.copyWith(
                  color: FigmaColors.neutral90,
                  fontSize: isMobile ? 18 : 20,
                ),
              ),
              
              SizedBox(height: isMobile ? 8 : 12),
              
              Text(
                'Découvrez les véhicules les plus fiables par catégorie, basés sur les données 2015-2024',
                style: textStyle.textMRegular.copyWith(
                  color: FigmaColors.neutral70,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Categories Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 2,
                  mainAxisSpacing: isMobile ? 16 : 20,
                  crossAxisSpacing: isMobile ? 16 : 20,
                  childAspectRatio: isMobile ? 1.2 : 1.1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(categories[index], textStyle, isMobile);
                },
              ),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Footer info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: FigmaColors.neutral10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FigmaColors.neutral20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: FigmaColors.primaryMain,
                          size: isMobile ? 20 : 24,
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Text(
                          'À propos de nos données',
                          style: textStyle.textMSemiBold.copyWith(
                            color: FigmaColors.neutral90,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    Text(
                      'Ces classements sont basés sur une analyse approfondie des données de fiabilité '
                      'collectées entre 2015 et 2024. Les notes reflètent la fréquence des pannes, '
                      'les coûts d\'entretien et la satisfaction des propriétaires.',
                      style: FigmaTextStyles().textMRegular.copyWith(
                        color: FigmaColors.neutral70,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ConseilCategory category, FigmaTextStyles textStyle, bool isMobile) {
    return GestureDetector(
      onTap: () => _showCategoryDetails(category),
      child: Container(
        decoration: BoxDecoration(
          color: FigmaColors.neutral00,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FigmaColors.neutral20),
          boxShadow: [
            BoxShadow(
              color: FigmaColors.neutral20.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec icône
              Row(
                children: [
                  Container(
                    width: isMobile ? 40 : 48,
                    height: isMobile ? 40 : 48,
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.title,
                          style: textStyle.textMSemiBold.copyWith(
                            color: FigmaColors.neutral90,
                            fontSize: isMobile ? 14 : 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.subtitle,
                          style: FigmaTextStyles().textMMedium.copyWith(
                            color: FigmaColors.neutral70,
                            fontSize: isMobile ? 11 : 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isMobile ? 12 : 16),
              
              // Aperçu des top items
              ...category.items.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: FigmaTextStyles().textMRegular.copyWith(
                            color: FigmaColors.neutral80,
                            fontSize: isMobile ? 11 : 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              const Spacer(),
              
              // Bouton voir plus
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 10,
                  horizontal: isMobile ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir le classement complet',
                      style: FigmaTextStyles().textMMedium.copyWith(
                        color: category.color,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: category.color,
                      size: isMobile ? 12 : 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryDetails(ConseilCategory category) {
    final textStyle = FigmaTextStyles();
    final isMobile = ResponsiveHelper.isMobile(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: FigmaColors.neutral00,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FigmaColors.neutral30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                child: Row(
                  children: [
                    Container(
                      width: isMobile ? 48 : 56,
                      height: isMobile ? 48 : 56,
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: textStyle.textLBold.copyWith(
                              color: FigmaColors.neutral90,
                              fontSize: isMobile ? 18 : 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.subtitle,
                            style: textStyle.textMRegular.copyWith(
                              color: FigmaColors.neutral70,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 24),
                  itemCount: category.items.length,
                  itemBuilder: (context, index) {
                    final item = category.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: FigmaColors.neutral10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FigmaColors.neutral20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isMobile ? 24 : 28,
                            height: isMobile ? 24 : 28,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: FigmaTextStyles().textMSemiBold.copyWith(
                                  color: Colors.white,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item,
                              style: textStyle.textMSemiBold.copyWith(
                                color: FigmaColors.neutral90,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}