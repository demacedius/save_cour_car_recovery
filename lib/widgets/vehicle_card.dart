import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/screens/vehicle/vehicle_detail.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/responsive_helper.dart';

class VehicleCard extends StatelessWidget {
  final VehicleData vehicle;
  
  const VehicleCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => {
        Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleDetail(vehicle: vehicle)),
        )
      },
      child: Container(
        width: ResponsiveHelper.cardWidth(context),
        margin: EdgeInsets.only(right: ResponsiveHelper.responsiveSpacing(context)),
        padding: EdgeInsets.all(ResponsiveHelper.responsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
        decoration: BoxDecoration(
          color: FigmaColors.neutral10,
          borderRadius: BorderRadius.circular(24),
          border: Border(bottom: BorderSide.none)
          
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ Hug content
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              
              children: [
                // Image du véhicule depuis l'API ou image par défaut
                SizedBox(
                  width: ResponsiveHelper.vehicleCardSize(context).width,
                  height: ResponsiveHelper.vehicleCardSize(context).height,
                  child: vehicle.imageUrl != null 
                    ? Image.network(
                        vehicle.imageUrl!, 
                        width: ResponsiveHelper.vehicleCardSize(context).width,
                        height: ResponsiveHelper.vehicleCardSize(context).height,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                          Image.asset('assets/images/car-parts 1.png', fit: BoxFit.cover),
                      )
                    : Image.asset('assets/images/car-parts 1.png', fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
               
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: FigmaColors.primaryFocus
                        ),
                        child: Text(
                          vehicle.year?.toString() ?? "N/A",
                          style: const TextStyle(fontSize: 12, color: FigmaColors.primaryMain),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${vehicle.brand} ${vehicle.model}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Logo de la marque depuis l'API ou logo par défaut
                      vehicle.brandImageUrl != null 
                        ? Image.network(
                            vehicle.brandImageUrl!, 
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.directions_car, size: 20),
                          )
                        : const Icon(Icons.directions_car, size: 20),
                    ],
                  ),
                ),
                const Icon(Icons.star, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1, color: FigmaColors.neutral20,),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _SpecItem(icon: Icons.confirmation_number, label: vehicle.plate),
                if (vehicle.mileage != null)
                  _SpecItem(icon: Icons.speed, label: "${vehicle.mileage} km"),
                _SpecItem(icon: Icons.directions_car, label: vehicle.brand),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
