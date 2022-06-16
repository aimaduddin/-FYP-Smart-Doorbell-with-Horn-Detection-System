// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:smart_doorbell_with_horn_detection/model/Audio.dart';
import 'package:smart_doorbell_with_horn_detection/screen/addvoice.dart';
import 'package:smart_doorbell_with_horn_detection/screen/historylogs.dart';
import 'package:smart_doorbell_with_horn_detection/utils/api.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';
import 'package:smart_doorbell_with_horn_detection/utils/mqtt_manager.dart';
import 'package:smart_doorbell_with_horn_detection/widgets/actionbutton.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Audio> _audios = [];
  String deleteMessage = "";
  bool deleteStatus = false;

  // MQTT
  late final MqttServerClient mqtt;
  final topic1 = 'horndoorbell'; // Not a wildcard topic
  bool relayStatus = false; // by default the relay is off.

  // JITSI Voice Call feature
  bool? isAudioOnly = true;
  bool? isAudioMuted = true;
  bool? isVideoMuted = true;

  // Audio player for audio preview
  AudioPlayer audioPlayer = new AudioPlayer();

  // [Function] To get recorded audio files from API
  _getAudios() {
    API.getListOfAudios().then((response) {
      setState(() {
        Iterable list = json.decode(response.body);
        _audios = list.map((model) => Audio.fromJson(model)).toList();
      });
    });
  }

  // [Function] Delete audio file from API
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

  Future<void> initMQTT() async {
    mqtt = await mqttManager();
  }

  // [Function] Sending the MQTT command to the MQTT broker
  sendMQTTCommand(String number) {
    final builder1 = MqttClientPayloadBuilder();

    builder1.addString(number);
    print('EXAMPLE:: <<<< PUBLISH 1 >>>>');
    mqtt.publishMessage(topic1, MqttQos.atLeastOnce, builder1.payload!);

    mqtt.updates!.listen((dynamic c) {
      final MqttPublishMessage recMess = c[0].payload;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });

    mqtt.published!.listen((MqttPublishMessage message) {
      print(
          'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    });
  }

  @override
  void initState() {
    super.initState();
    initMQTT();
    _getAudios();
    JitsiMeet.addListener(JitsiMeetingListener(
        onConferenceWillJoin: _onConferenceWillJoin,
        onConferenceJoined: _onConferenceJoined,
        onConferenceTerminated: _onConferenceTerminated,
        onError: _onError));
  }

  @override
  void dispose() {
    super.dispose();
    JitsiMeet.removeAllListeners();
  }

  @override
  Widget build(BuildContext context) {
    // For live streaming webcam
    bool isRunning = true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryLogs(),
                ),
              );
            },
            icon: Icon(Icons.history_outlined),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 25, 15, 25),
          child: Column(
            children: [
              Text(
                liveVideoFeedTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              height15,
              Mjpeg(
                isLive: isRunning,
                error: (context, error, stack) {
                  print(error);
                  print(stack);
                  return Text(error.toString(),
                      style: TextStyle(color: Colors.red));
                },
                stream:
                    'http://192.168.1.123:8000/stream.mjpg', // Put the IP Address of Raspberry Pi that serve the Camera's view.
              ),
              height15,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  relayStatus
                      ? ActionButton(
                          icon: Icons.lock,
                          textInButton: "Close Gate",
                          callback: () async {
                            setState(() {
                              relayStatus = false;
                              sendMQTTCommand("offgate");
                            });

                            String logs = "The gate has been closed";
                            await API.createLog(logs, "4");
                          },
                        )
                      : ActionButton(
                          icon: Icons.lock_open,
                          textInButton: "Open Gate",
                          callback: () async {
                            setState(() {
                              relayStatus = true;
                              sendMQTTCommand("ongate");
                            });

                            String logs = "The gate has been opened";
                            await API.createLog(logs, "3");
                          },
                        ),
                  ActionButton(
                    icon: Icons.call,
                    textInButton: "Voice Call",
                    callback: () async {
                      String logs = "The voice call session has been started";
                      await API.createLog(logs, "1");
                      _joinMeeting();
                    },
                  ),
                ],
              ),
              height15,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Send Pre-Recorded Voice',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            onPressed: (value) {
              getPlayAudio(_audios[index].name);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.play_arrow,
            label: 'Preview',
          ),
          SlidableAction(
            onPressed: (value) async {
              // send api to delete audio from the server
              _deleteAudio(_audios[index].id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(deleteMessage),
                ),
              );

              // create log
              String logs =
                  "The recorded message (${_audios[index].name}) has been deleted";
              await API.createLog(logs, "6");

              // refresh the current list of pre-recorded messages.
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
            // display the title of the pre-recorded message
            leading: Text((index + 1).toString()),
            title: Text(
              _audios[index].title,
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // display the date created of the pre-recorded message
                Text('Created on ${_audios[index].date}'),
              ],
            ),
            trailing: IconButton(
              onPressed: () async {
                // send mqtt command (audio title) to mqtt brocker
                sendMQTTCommand(_audios[index].name);
                String logs = "The " +
                    _audios[index].name +
                    " sound has been played to the doorbell";
                // log the action
                await API.createLog(logs, "2");
              },
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

  // JITSI Voice Call functions
  _onAudioOnlyChanged(bool? value) {
    setState(() {
      isAudioOnly = value;
    });
  }

  _onAudioMutedChanged(bool? value) {
    setState(() {
      isAudioMuted = value;
    });
  }

  _onVideoMutedChanged(bool? value) {
    setState(() {
      isVideoMuted = value;
    });
  }

  _joinMeeting() async {
    String? serverUrl = null;
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
    };
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      }
    }
    // Define meetings options here
    var options = JitsiMeetingOptions(room: "aimasmarthorndoorbell")
      ..serverURL = serverUrl
      ..subject = "Smart Doorbell with Horn Detection"
      ..userDisplayName = "User"
      ..userEmail = "aima10.aima11@gmail.com"
      ..iosAppBarRGBAColor = "#0080FF80"
      ..audioOnly = isAudioOnly
      ..audioMuted = isAudioMuted
      ..videoMuted = isVideoMuted
      ..featureFlags.addAll(featureFlags)
      ..webOptions = {
        "roomName": "aimasmarthorndoorbell",
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "userInfo": {"displayName": "User"}
      };

    debugPrint("JitsiMeetingOptions: $options");
    await JitsiMeet.joinMeeting(
      options,
      listener: JitsiMeetingListener(
          onConferenceWillJoin: (message) {
            debugPrint("${options.room} will join with message: $message");
          },
          onConferenceJoined: (message) {
            debugPrint("${options.room} joined with message: $message");
          },
          onConferenceTerminated: (message) {
            debugPrint("${options.room} terminated with message: $message");
          },
          genericListeners: [
            JitsiGenericListener(
                eventName: 'readyToClose',
                callback: (dynamic message) {
                  debugPrint("readyToClose callback");
                }),
          ]),
    );
  }

  void _onConferenceWillJoin(message) {
    debugPrint("_onConferenceWillJoin broadcasted with message: $message");
  }

  void _onConferenceJoined(message) {
    debugPrint("_onConferenceJoined broadcasted with message: $message");
  }

  void _onConferenceTerminated(message) {
    debugPrint("_onConferenceTerminated broadcasted with message: $message");
  }

  _onError(error) {
    debugPrint("_onError broadcasted: $error");
  }

  // [Function] Play / Preview pre-recorded audio from homepage screen.
  void getPlayAudio(String fileName) async {
    var url = "https://aimaduddin.com/Smart-Doorbell/upload/${fileName}";

    var res = await audioPlayer.play(url, isLocal: true);
  }
}
