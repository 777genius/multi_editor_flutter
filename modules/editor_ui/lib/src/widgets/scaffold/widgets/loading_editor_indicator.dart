import 'package:flutter/material.dart';

class LoadingEditorIndicator extends StatelessWidget {
  const LoadingEditorIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
