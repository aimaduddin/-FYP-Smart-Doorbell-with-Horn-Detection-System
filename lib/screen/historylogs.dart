import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smart_doorbell_with_horn_detection/model/Log.dart';
import 'package:smart_doorbell_with_horn_detection/utils/api.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';

class HistoryLogs extends StatefulWidget {
  const HistoryLogs({Key? key}) : super(key: key);

  @override
  State<HistoryLogs> createState() => _HistoryLogsState();
}

class _HistoryLogsState extends State<HistoryLogs> {
  List<Log> _logs = [];

  _getLogs() {
    API.getListOfLogs().then((response) {
      setState(() {
        Iterable list = json.decode(response.body);
        _logs = list.map((model) => Log.fromJson(model)).toList();
      });
    });

    print(_logs);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(15, 25, 15, 25),
        child: Column(
          children: [
            Text(historyLogsTitle),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) => logDetailCard(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget logDetailCard(int index) {
    return Card(
      elevation: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: _logs[index].activity_type_id == "1"
                ? Icon(Icons.phone, size: 30)
                : Icon(Icons.speaker, size: 30),
            title: Text(_logs[index].activity),
            subtitle: Text(_logs[index].date),
          ),
        ],
      ),
    );
  }
}
