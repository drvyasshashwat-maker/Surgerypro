import 'package:flutter/material.dart';

class ProgressFeedList extends StatelessWidget {
  final List<String> progressItems;

  ProgressFeedList({required this.progressItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: progressItems.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(progressItems[index]),
        );
      },
    );
  }
}