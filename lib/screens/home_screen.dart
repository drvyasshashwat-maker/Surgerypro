import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _progressFeed = [];
  int _selectedTabIndex = 0;

  void _sendMessage() {
    // Add input text to progress feed
    setState(() {
      _progressFeed.add(_textController.text);
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
        bottom: TabBar(
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          tabs: [
            Tab(text: 'Result 1'),
            Tab(text: 'Result 2'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _resultTab('Result 1'),
          _resultTab('Result 2'),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultTab(String title) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: TextStyle(fontSize: 24)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _progressFeed.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_progressFeed[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
