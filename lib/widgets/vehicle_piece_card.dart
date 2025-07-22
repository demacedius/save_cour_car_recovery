import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';

class PiecesCard extends StatelessWidget {
  PiecesCard({super.key});
  final textStyle = FigmaTextStyles();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset("assets/images/car-parts 1.png", width: 64,height: 50,fit: BoxFit.contain,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nom de la pièce", style: textStyle.textXLBold),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8,vertical: 6),  
                  decoration: BoxDecoration(
                    color: FigmaColors.primaryFocus,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text("Catégorie", style: textStyle.textMMedium.copyWith(color:FigmaColors.primaryMain)),
                ),
              ],
            ),
            Icon(size:25,Icons.star_rounded, color: FigmaColors.warningOrangeMain,)
          ],
        ),
      ),
    );
  }
}
