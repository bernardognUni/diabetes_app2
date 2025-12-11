import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color = const Color(0xFF3D43FF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }
}
