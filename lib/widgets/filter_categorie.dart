import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';

class FilterCategory extends StatefulWidget {
  const FilterCategory({super.key});

  @override
  State<FilterCategory> createState() => _FilterCategoryState();
}

class _FilterCategoryState extends State<FilterCategory> {
  final textStyle = FigmaTextStyles();
  int SelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final filterName = ["All", "Boite de vitesse", "Moteur", "Roue", "Ammortiseur", "Carrosserie"];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterName.length,
        itemBuilder: (context, index) {
          final isSelected = index == SelectedIndex;

          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 0, right: 12),
            child: GestureDetector(
              onTap:
                  () => {
                    setState(() {
                      SelectedIndex = index;
                    }),
                  },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF141316) : FigmaColors.neutral10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  filterName[index],
                  style: textStyle.textMSemiBold.copyWith(
                    color:
                        isSelected
                            ? FigmaColors.neutral00
                            : FigmaColors.neutral100,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
