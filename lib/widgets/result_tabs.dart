import 'package:flutter/material.dart';

class ResultTabs extends StatefulWidget {
  @override
  _ResultTabsState createState() => _ResultTabsState();
}

class _ResultTabsState extends State<ResultTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result Tabs'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Notes'),
            Tab(text: 'MCQs'),
            Tab(text: 'SAQs'),
            Tab(text: 'LAQs'),
            Tab(text: 'Viva'),
            Tab(text: 'Cards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: Text('Notes Content')), // Replace with actual content
          Center(child: Text('MCQs Content')), // Replace with actual content
          Center(child: Text('SAQs Content')), // Replace with actual content
          Center(child: Text('LAQs Content')), // Replace with actual content
          Center(child: Text('Viva Content')), // Replace with actual content
          Center(child: Text('Cards Content')), // Replace with actual content
        ],
      ),
    );
  }
}