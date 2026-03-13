import 'package:flutter/widgets.dart';

class BranchAssignment {
  BranchAssignment({this.branchId, int minThreshold = 0})
    : thresholdCtrl = TextEditingController(text: minThreshold.toString());

  String? branchId;
  final TextEditingController thresholdCtrl;
}
