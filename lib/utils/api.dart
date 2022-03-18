import 'dart:async';
import 'package:http/http.dart' as http;

const baseUrl = "https://aimaduddin.com/Smart-Doorbell";

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
