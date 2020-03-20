import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_view.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
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

FutureOr<List<CountryDataModel>> getCountryInformation(int a) async {
  List<CountryDataModel> countryData;

  var client = Client();
  Response response =
      await client.get('https://www.worldometers.info/coronavirus/');

  dom.Document document = parser.parse(response.body);
  dom.Element table = document.getElementById("main_table_countries_today");
  countryData = List();

  for (dom.Element tableChild in table.children) {
    for (dom.Element eachDataTable in tableChild.children) {
      CountryDataModel model = CountryDataModel(
          eachDataTable.children[0].text,
          eachDataTable.children[1].text,
          eachDataTable.children[2].text,
          eachDataTable.children[3].text,
          eachDataTable.children[4].text,
          eachDataTable.children[5].text,
          eachDataTable.children[6].text,
          eachDataTable.children[7].text,
          eachDataTable.children[8].text);
      if (model.newDeaths.contains("+")) {
        model.newDeathColor = Colors.red;
      }
      countryData.add(model);
    }
  }
  return countryData;
}

Future<List<SummaryDataModel>> getSummaryInformation(int a) async {
  List<SummaryDataModel> summaryData;
  var client = Client();
  Response response =
      await client.get('https://www.worldometers.info/coronavirus/');

  dom.Document document = parser.parse(response.body);
  List<dom.Element> elements = document.querySelectorAll("#maincounter-wrap");
  summaryData = List();
  for (dom.Element element in elements) {
    print(element.querySelector("h1").text);
    dom.Element number = element.querySelector("div.maincounter-number");
    dom.Element span = number.querySelector("span");
    print(span.text);
    summaryData
        .add(SummaryDataModel(element.querySelector("h1").text, span.text));
  }
  return summaryData;
}

FutureOr<String> getChart(int a) async {
  var client = Client();
  Response response =
      await client.get('https://www.worldometers.info/coronavirus/');

  dom.Document document = parser.parse(response.body);
  dom.Element chart = document.querySelector('div.tabbable-panel-cases');
//  chart.


  return chart.toString();
}

class _CounterState extends State<Counter> {
  bool isFirstSummaryData;
  List<SummaryDataModel> summaryData = List();
  bool isLoadingSummaryData;

  bool isFirstCountryData;
  List<CountryDataModel> countryData = List();
  bool isLoadingCountryData;
  String graphHTMLData;

  @override
  void initState() {
    super.initState();

    isFirstSummaryData = true;
    isLoadingSummaryData = true;
    init();
  }

  updateCountryData() async {
    isLoadingCountryData = true;
    setState(() {});
    countryData = await compute(getCountryInformation, 1);
    isFirstCountryData = false;
    isLoadingCountryData = false;
    setState(() {});
  }

  updateSummaryInformation() async {
    isLoadingSummaryData = true;
    setState(() {});
    summaryData = await compute(getSummaryInformation, 1);
    isFirstSummaryData = false;
    isLoadingSummaryData = false;
    setState(() {});
  }

  updateGraphHTMLData() async {
    graphHTMLData = await compute(getChart, 1);
    setState(() {});
  }

  init() {
    updateCountryData();
    updateSummaryInformation();
//    updateGraphHTMLData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Corona- data"),
        actions: <Widget>[
          FlatButton(
            onPressed: init,
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 16,
                ),
                Text(
                  'Refresh',
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 2.3,
            child: isFirstSummaryData && isLoadingSummaryData
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : isLoadingSummaryData &&
                        (summaryData == null || summaryData.length == 0)
                    ? Center(
                        child: Text('Some thing went wrong'),
                      )
                    : Column(
                        children: List.generate(summaryData.length, (index) {
                          return ListTile(
                            title: Text(summaryData[index].title.trim()),
                            trailing: Text(summaryData[index].value.trim()),
                          );
                        })
                          ..add(isLoadingSummaryData
                              ? LinearProgressIndicator()
                              : Container()),
                      ),
          ),
//          graphHTMLData != null
//              ? SizedBox(
//                  height: 300,
//                  width: double.infinity,
//                  child: HtmlView(
//                    data: graphHTMLData,
//                  ),
//                )
//              : SizedBox(),
          Text(
            'Report coronavirus cases',
            style: Theme.of(context).textTheme.display1,
          ),
          countryData == null
              ? CircularProgressIndicator()
              : countryData.length == 0
                  ? Text('No data found')
                  : Expanded(child: _getBodyWidget())
        ],
      ),
    );
  }

  Widget _getBodyWidget() {
    return HorizontalDataTable(
      leftHandSideColumnWidth: 1,
      rightHandSideColumnWidth: 1370,
      isFixedHeader: true,
      headerWidgets: _getTitleWidget(countryData[0], context),
      leftSideItemBuilder: _generateFirstColumnRow,
      rightSideItemBuilder: _generateRightHandSideColumnRow,
      itemCount: countryData.length - 1,
      rowSeparatorWidget: const Divider(
        color: Colors.black54,
        height: 1.0,
        thickness: 0.0,
      ),
      leftHandSideColBackgroundColor: Color(0xFFFFFFFF),
      rightHandSideColBackgroundColor: Color(0xFFFFFFFF),
    );
  }

  List<Widget> _getTitleWidget(each, context) {
    return [
      Container(),
    ]..addAll(getCountryWidget(each, context, 0));
  }

  Widget _getTitleItemWidget(String label, double width) {
    return Container(
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      width: width,
      height: 56,
      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.centerLeft,
    );
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {
    return Container(
//      color: Colors.redAccent,
//      child: Text(user.userInfo[index].name),
//      width: 150,
//      height: 52,
//      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
//      alignment: Alignment.centerLeft,
        );
  }

  Widget _generateRightHandSideColumnRow(BuildContext context, int index) {
    var each = countryData[index + 1];
    return Row(
      children: getCountryWidget(each, context, index + 1),
    );
  }
}

Widget getDivider() {
  return Container(
    width: 1,
    height: 50,
    color: Colors.grey,
  );
}

List<Widget> getCountryWidget(CountryDataModel each, context, index) {
  return <Widget>[
    Container(
      alignment: Alignment.center,
      width: 150,
      height: 50,
      child: Text(each.name,
          style: index != 0 ? Theme.of(context).textTheme.title : null),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 150,
      child: Text(each.totalCases),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 150,
      child: Text(each.newCases),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 150,
      child: Text(each.totalDeaths),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 150,
      height: 50,
      color: each.newDeathColor,
      child: Text(each.newDeaths),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 120,
      child: Text(each.totalRecovered),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 150,
      child: Text(each.activeCases),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 150,
      child: Text(each.seriousCritical),
    ),
    getDivider(),
    Container(
      alignment: Alignment.center,
      width: 150,
      child: Text(each.totalCases1MPopUp),
    ),
  ];
}

class SummaryDataModel {
  final String title;
  final String value;

  SummaryDataModel(this.title, this.value);
}

class CountryDataModel {
  final String name;
  final String totalCases;
  final String newCases;
  final String totalDeaths;
  final String newDeaths;

  final String totalRecovered;
  final String activeCases;
  final String seriousCritical;
  final String totalCases1MPopUp;
  Color newDeathColor;

  CountryDataModel(
      this.name,
      this.totalCases,
      this.newCases,
      this.totalDeaths,
      this.newDeaths,
      this.totalRecovered,
      this.activeCases,
      this.seriousCritical,
      this.totalCases1MPopUp,
      {this.newDeathColor = Colors.white});
}
/*
 Table(
                children: List.generate(countryData.length, (index) {
              CountryDataModel each = countryData[index];
              return TableRow(children: [
                TableCell(
                  child: Text(each.name),
                ),
                TableCell(
                  child: Text(each.totalCases),
                ),
                TableCell(
                  child: Text(each.newCases),
                ),
                TableCell(
                  child: Text(each.totalDeaths),
                ),
                TableCell(
                  child: Text(each.newDeaths),
                ),
                TableCell(
                  child: Text(each.totalRecovered),
                ),
                TableCell(
                  child: Text(each.activeCases),
                ),
                TableCell(
                  child: Text(each.seriousCritical),
                ),
                TableCell(
                  child: Text(each.totalCases1MPopUp),
                ),
              ]);
            }))
 */
