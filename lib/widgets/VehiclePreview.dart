import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/theme/figma_color.dart';

class VehiclePreview extends StatelessWidget {
  final Map data;

  const VehiclePreview({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marque : ${data['brand']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Modèle : ${data['model']}'),
          Text('Année : ${data['year']}'),
          const SizedBox(height: 16),
          if (data['imageUrl'] != null)
            Center(child: Image.network(data['imageUrl'], height: 100)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ferme le bottom sheet
                Navigator.pushNamed(
                  context,
                  '/klm',
                  arguments: VehicleData(
                    plate: data['plate'] ?? '',
                    model: data['model'] ?? '',
                    brand: data['brand'] ?? '',
                    imageUrl: data['imageUrl'],
                    year: data['year'],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FigmaColors.primaryMain,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text("C'est mon véhicule"),
            ),
          ),
        ],
      ),
    );
  }
}
