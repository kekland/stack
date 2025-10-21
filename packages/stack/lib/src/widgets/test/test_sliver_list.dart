import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

class TestSliverList extends StatelessWidget {
  const TestSliverList({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: 100,
      itemBuilder: (context, index) {
        return Container(
          height: 100,
          color: index.isEven ? Colors.black.withMultipliedOpacity(0.05) : Colors.black.withMultipliedOpacity(0.1),
          child: Center(
            child: Text(
              '$index',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
