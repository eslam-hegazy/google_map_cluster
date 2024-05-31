import 'package:flutter/material.dart';
import 'package:rahaly/place_model.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class MarkerWidget extends StatelessWidget {
  const MarkerWidget({
    super.key,
    required this.place,
  });
  final Place place;

  @override
  Widget build(BuildContext context) {
    return CircularStepProgressIndicator(
      totalSteps: 100,
      currentStep: 100,
      stepSize: 1,
      selectedColor: Colors.blue,
      unselectedColor: Colors.transparent,
      padding: 0,
      width: 50,
      height: 50,
      unselectedStepSize: 3,
      selectedStepSize: 3,
      roundedCap: (_, __) => true,
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Text(
          place.name,
          style: const TextStyle(fontSize: 6),
        ),
      ),
    );
  }
}
