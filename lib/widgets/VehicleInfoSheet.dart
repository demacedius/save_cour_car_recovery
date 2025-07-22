import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';

class VehicleInfoSheet extends StatelessWidget {
  final Map data;

  const VehicleInfoSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marque : ${data['brand']}'),
          Text('Modèle : ${data['model']}'),
          Text('Année : ${data['year']}'),
          Text('Marque : ${data['brand']}'),
          Image.network(data['imageUrl'], height: 100),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Ferme le sheet
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
            child: const Text("C'est mon véhicule"),
          ),
        ],
      ),
    );
  }
}
