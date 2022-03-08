import 'dart:async';
import 'package:http/http.dart' as http;

const baseUrl = "http://192.168.0.120/smart-doorbell";

class API {
  static Future getListOfAudios() {
    var url = baseUrl + "/list_of_audios.php";
    return http.get(Uri.parse(url));
  }

  static Future deleteAudio(String id) {
    var url = baseUrl + "/delete.php?file_id=" + id;
    return http.get(Uri.parse(url));
  }
}
