import 'package:flutter/material.dart';

class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Center(
        child: Text('To-Do List Screen'),
      ),
    );
  }
}
