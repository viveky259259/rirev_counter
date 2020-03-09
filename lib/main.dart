import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart'; // Contains a client for making API calls

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Counter(),
    );
  }
}

class Counter extends StatefulWidget {
  @override
  _CounterState createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  Future<List<ElementData>> getInformation() async {
    List<ElementData> data = List();
    var client = Client();
    Response response =
        await client.get('https://www.worldometers.info/coronavirus-dev/');

    dom.Document document = parser.parse(response.body);
    List<dom.Element> elements = document.querySelectorAll("#maincounter-wrap");
    for (dom.Element element in elements) {
      print(element.querySelector("h1").text);
      dom.Element number = element.querySelector("div.maincounter-number");
      dom.Element span = number.querySelector("span");
      print(span.text);
      data.add(ElementData(element.querySelector("h1").text, span.text));
    }
    return data;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  init() {
    Timer.periodic(Duration(seconds: 10), (_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Corona- data"),
      ),
      body: FutureBuilder<List<ElementData>>(
        future: getInformation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.data != null && snapshot.data.length > 0) {
            return Column(
              children: List.generate(snapshot.data.length, (index) {
                return ListTile(
                  title: Text(snapshot.data[index].title.trim()),
                  trailing: Text(snapshot.data[index].value.trim()),
                );
              }),
            );
          } else
            return Text("Try again later");
        },
      ),
    );
  }
}

class ElementData {
  final String title;
  final String value;

  ElementData(this.title, this.value);
}
