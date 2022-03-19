// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';

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

  // JITSI Voice Call feature
  bool? isAudioOnly = true;
  bool? isAudioMuted = true;
  bool? isVideoMuted = true;

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

  Future<void> initMQTT() async {
    mqtt = await mqttManager();
  }

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

    /// If needed you can listen for published messages that have completed the publishing
    /// handshake which is Qos dependant. Any message received on this stream has completed its
    /// publishing handshake with the broker.
    mqtt.published!.listen((MqttPublishMessage message) {
      print(
          'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
      // if (message.variableHeader!.topicName == topic3) {
      //   print('EXAMPLE:: Non subscribed topic received.');
      // }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
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
    // TODO: implement dispose
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
            icon: Icon(Icons.history),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 25, 15, 25),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(liveVideoFeedTitle),
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
                    'http://192.168.0.178:8000/stream.mjpg', //'http://192.168.1.37:8081',
              ),
              height15,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ActionButton(
                    icon: Icons.speaker,
                    textInButton: "Toggle Video",
                    callback: () {
                      setState(() {
                        isRunning = !isRunning;
                      });
                    },
                  ),
                  ActionButton(
                    icon: Icons.call,
                    textInButton: "Voice Call",
                    callback: () async {
                      String logs = "The voice call session has been started";
                      await API.createLog(logs, "1");
                      // _joinMeeting();
                    },
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
            onPressed: null,
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
              onPressed: () async {
                sendMQTTCommand(_audios[index].name);
                print('clicked');
                String logs = "The " +
                    _audios[index].name +
                    "sound has been played to the doorbell";
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

    // Enable or disable any feature flag here
    // If feature flag are not provided, default values will be used
    // Full list of feature flags (and defaults) available in the README
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
    };
    if (!kIsWeb) {
      // Here is an example, disabling features for each platform
      if (Platform.isAndroid) {
        // Disable ConnectionService usage on Android to avoid issues (see README)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        // Disable PIP on iOS as it looks weird
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
}
