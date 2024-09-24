// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? icon;
  final TextEditingController? controller;
  final double? inputWidth;
  final VoidCallback? onTap;

  const CustomTextField({super.key, 
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.icon,
    this.controller,
    this.inputWidth,
    this.onTap,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.inputWidth ?? MediaQuery.of(context).size.width * 0.8,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
          prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
        ),
        keyboardType: widget.keyboardType,
        obscureText: widget.isPassword && _isObscure,
        onTap: widget.onTap, // Passando a função onTap
      ),
    );
  }
}
