import 'dart:convert';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_doorbell_with_horn_detection/screen/homepage.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';
import 'package:smart_doorbell_with_horn_detection/widgets/actionbutton.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

typedef _Fn = void Function();
const theSource = AudioSource.microphone;

class AddVoice extends StatefulWidget {
  const AddVoice({Key? key}) : super(key: key);

  @override
  State<AddVoice> createState() => _AddVoiceState();
}

class _AddVoiceState extends State<AddVoice> {
  final _formKey = GlobalKey<FormState>();
  String titleOfAudio = "";

  // Get current date and time for temp voice file name.
  // String fdatetime = DateFormat('dd-MMM-yyy').format(
  //     DateTime.fromMillisecondsSinceEpoch(DateTime.now()
  //         .millisecondsSinceEpoch)); //DateFormat() is from intl package

  // For recorder and player
  Codec _codec = Codec.pcm16WAV;
  String _mPath = '/sdcard/Download/recordedFile.wav';
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;
  String uploadMessage = "";
  bool uploadStatus = false;

  // For uploading the voice file
  String uploadURL = "https://aimaduddin.com/Smart-Doorbell/upload.php";

  Future uploadFile() async {
    var request = http.MultipartRequest('POST', Uri.parse(uploadURL));
    request.files.add(
      await http.MultipartFile.fromPath('sendaudio', _mPath),
    );
    request.fields['title'] = titleOfAudio;
    var res = await request.send();
    var responsed = await http.Response.fromStream(res);
    var result = json.decode(responsed.body);
    uploadMessage = result["message"];
    uploadStatus = result["status"];
  }

  @override
  void initState() {
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _mPlayer!.closePlayer();
    _mPlayer = null;

    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      var status2 = await Permission.manageExternalStorage.request();
      if (status != PermissionStatus.granted &&
          status2 != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = '/sdcard/Download/tau_file.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _mRecorderIsInited = true;
  }

  // ----------------------  Here is the code for recording and playback -------

  void record() {
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        //var url = value;
        _mplaybackReady = true;
      });
    });
  }

  void play() {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!
        .startPlayer(
            fromURI: _mPath,
            //codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
            whenFinished: () {
              setState(() {});
            })
        .then((value) {
      setState(() {});
    });
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

// ----------------------------- UI --------------------------------------------

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Voice'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: Column(
              children: [
                Text('Add New Voice Message'),
                height10,
                Text('Hold the microphone icon below to start recording.'),
                height5,
                Text('Once done, release it.'),
                height30,
                ElevatedButton(
                  onPressed: getRecorderFn(),
                  //color: Colors.white,
                  //disabledColor: Colors.grey,
                  child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
                ),
                SizedBox(
                  width: 20,
                ),
                Text(_mRecorder!.isRecording
                    ? 'Recording in progress'
                    : 'Recorder is stopped'),
                height30,
                Container(
                  margin: const EdgeInsets.all(3),
                  padding: const EdgeInsets.all(3),
                  height: 80,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(0xFFFAF0E6),
                    border: Border.all(
                      color: Colors.indigo,
                      width: 3,
                    ),
                  ),
                  child: Row(children: [
                    ElevatedButton(
                      onPressed: getPlaybackFn(),
                      //color: Colors.white,
                      //disabledColor: Colors.grey,
                      child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text(_mPlayer!.isPlaying
                        ? 'Playback in progress'
                        : 'Player is stopped'),
                  ]),
                ),
                height30,
                Form(
                  key: _formKey,
                  child: TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Title',
                      hintText: 'I\'m away from home.',
                      hintStyle: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the title of the voice message';
                      }
                      titleOfAudio = value;

                      return null;
                    },
                  ),
                ),
                height30,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ActionButton(
                      icon: Icons.cancel,
                      textInButton: 'Cancel',
                      borderColor: Color(0xfff44336),
                      callback: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ActionButton(
                      icon: Icons.save,
                      textInButton: 'Save',
                      borderColor: Color(0xff4caf50),
                      callback: () async {
                        if (_formKey.currentState!.validate()) {
                          await uploadFile();

                          if (uploadStatus) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(uploadMessage)),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(uploadMessage)),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
