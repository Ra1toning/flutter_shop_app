import 'dart:async';
import 'package:flutter/material.dart';
import '../src/widgets.dart';

class Comment extends StatefulWidget {
  const Comment({required this.addMessage, Key? key}) : super(key: key);

  final FutureOr<void> Function(String message) addMessage;

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_CommentState');
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Мессеж үлдээх',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Илгээх зүйлээ бичнэ үү';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            StyledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await widget.addMessage(_controller.text);
                  _controller.clear();
                }
              },
              child: const Row(
                children: [
                  Icon(Icons.send),
                  SizedBox(width: 4),
                  Text('ИЛГЭЭХ'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
