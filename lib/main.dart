import 'package:eatscikmitl/rootScreen.dart';
import 'package:flutter/material.dart';


void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eat@Sci',
      home: const RootScreen(currentScreens: 1),
      theme: ThemeData(
        primaryColor: Theme.of(context).scaffoldBackgroundColor
      ),
    );
  }
}