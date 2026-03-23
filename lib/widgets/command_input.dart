import 'package:flutter/material.dart';

class CommandInput extends StatefulWidget {
  final Function(String) onSend;

  CommandInput({required this.onSend});

  @override
  _CommandInputState createState() => _CommandInputState();
}

class _CommandInputState extends State<CommandInput> {
  final TextEditingController _controller = TextEditingController();

  void _sendCommand() {
    final command = _controller.text;
    if (command.isNotEmpty) {
      widget.onSend(command);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter command...',
            ),
            onSubmitted: (_) => _sendCommand(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: _sendCommand,
        ),
      ],
    );
  }
}