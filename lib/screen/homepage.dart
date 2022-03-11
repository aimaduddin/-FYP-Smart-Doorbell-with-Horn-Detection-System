// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smart_doorbell_with_horn_detection/model/Audio.dart';
import 'package:smart_doorbell_with_horn_detection/screen/addvoice.dart';
import 'package:smart_doorbell_with_horn_detection/utils/api.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';
import 'package:smart_doorbell_with_horn_detection/widgets/actionbutton.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Audio> _audios = [];
  String deleteMessage = "";
  bool deleteStatus = false;

  _getAudios() {
    API.getListOfAudios().then((response) {
      setState(() {
        Iterable list = json.decode(response.body);
        _audios = list.map((model) => Audio.fromJson(model)).toList();
      });
    });
  }

  _deleteAudio(String id) {
    API.deleteAudio(id).then((response) {
      setState(() {
        Map<String, dynamic> message = json.decode(response.body);
        deleteMessage = message['message'];
        deleteStatus = message['status'];
        print(deleteMessage);
        print(deleteStatus);
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getAudios();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(appTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 25, 15, 25),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(liveVideoFeedTitle),
              height15,
              Image.network("http://via.placeholder.com/640x360"),
              height15,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ActionButton(
                    icon: Icons.speaker,
                    textInButton: "Listen",
                    callback: () {},
                  ),
                  ActionButton(
                    icon: Icons.call,
                    textInButton: "Voice Call",
                    callback: () {},
                  ),
                ],
              ),
              height15,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Send Pre-Recorded Voice'),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddVoice(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add),
                    color: Colors.blue,
                  ),
                ],
              ),
              height15,
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _audios.length,
                  itemBuilder: (context, index) => SlideableVoiceCard(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Slidable SlideableVoiceCard(int index) {
    return Slidable(
      // Specify a key if the Slidable is dismissible.
      key: const ValueKey(0),

      // The end action pane is the one at the right or the bottom side.
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            // An action can be bigger than the others.
            onPressed: doNothing,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.play_arrow,
            label: 'Preview',
          ),
          SlidableAction(
            onPressed: (value) {
              _deleteAudio(_audios[index].id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(deleteMessage),
                ),
              );
              _getAudios();
            },
            backgroundColor: Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),

      // The child of the Slidable is what the user sees when the
      // component is not dragged.
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Text((index + 1).toString()),
            title: Text(_audios[index].title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_audios[index].name),
                Text(_audios[index].date),
              ],
            ),
            trailing: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.send,
                color: Colors.green,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void doNothing(BuildContext context) {}
