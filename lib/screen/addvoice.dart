import 'package:flutter/material.dart';
import 'package:smart_doorbell_with_horn_detection/utils/const.dart';
import 'package:smart_doorbell_with_horn_detection/widgets/actionbutton.dart';

class AddVoice extends StatefulWidget {
  const AddVoice({Key? key}) : super(key: key);

  @override
  State<AddVoice> createState() => _AddVoiceState();
}

class _AddVoiceState extends State<AddVoice> {
  final _formKey = GlobalKey<FormState>();

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
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.mic),
                  iconSize: 200,
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
                      callback: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')),
                          );
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
