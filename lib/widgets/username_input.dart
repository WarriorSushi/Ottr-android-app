// Flutter imports
import 'package:flutter/material.dart';

// Project imports
import 'package:ottr/utils/constants.dart';
import 'package:ottr/utils/validators.dart';

/// Reusable widget for username input with validation
class UsernameInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String username) onSubmitted;
  final String buttonLabel;
  final String? hintText;

  const UsernameInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSubmitted,
    required this.buttonLabel,
    this.hintText,
  });

  @override
  State<UsernameInput> createState() => _UsernameInputState();
}

class _UsernameInputState extends State<UsernameInput> {
  final _formKey = GlobalKey<FormState>();

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmitted(widget.controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username input field
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: widget.hintText ?? 'Enter a username',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              enabled: !widget.isLoading,
              validator: usernameValidator,
              textInputAction: TextInputAction.go,
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
          ),
          const SizedBox(width: 12),
          
          // Submit button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
