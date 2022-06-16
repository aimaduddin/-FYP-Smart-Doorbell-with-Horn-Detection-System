import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = "https://aimaduddin.com/Smart-Doorbell/";

class API {
  static Future getListOfAudios() {
    var url = baseUrl + "/list_of_audios.php";
    return http.get(Uri.parse(url));
  }

  static Future deleteAudio(String id) {
    var url = baseUrl + "/delete.php?file_id=" + id;
    return http.get(Uri.parse(url));
  }

  static Future getListOfLogs() {
    var url = baseUrl + "/list_of_logs.php";
    return http.get(Uri.parse(url));
  }

  static Future createLog(String activityLog, String activityType) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse(baseUrl + "/create_history_logs.php"));
    request.fields['activity'] = activityLog;
    request.fields['type'] = activityType;
    var res = await request.send();
    var responsed = await http.Response.fromStream(res);
    var result = json.decode(responsed.body);

    return result;
  }
}
