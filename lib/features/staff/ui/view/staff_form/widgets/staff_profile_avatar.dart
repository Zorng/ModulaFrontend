import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StaffProfileAvatar extends StatelessWidget {
  const StaffProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.black12,
            child: Icon(
              CupertinoIcons.person_fill,
              size: 60,
              color: Colors.white,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                CupertinoIcons.camera_fill,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

