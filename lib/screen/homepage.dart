// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smart_doorbell_with_horn_detection/screen/addvoice.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';
import 'package:smart_doorbell_with_horn_detection/widgets/actionbutton.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List dummyList = List.generate(10, (index) {
    return {
      "id": index,
      "title": "This is the title $index",
      "subtitle": "This is the subtitle $index"
    };
  });

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
                  itemCount: dummyList.length,
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
      endActionPane: const ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            // An action can be bigger than the others.
            onPressed: doNothing,
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: doNothing,
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
        child: ListTile(
          leading: Text(dummyList[index]["id"].toString()),
          title: Text(dummyList[index]["title"]),
          subtitle: Text(dummyList[index]["subtitle"]),
          trailing: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.send,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}

void doNothing(BuildContext context) {}
