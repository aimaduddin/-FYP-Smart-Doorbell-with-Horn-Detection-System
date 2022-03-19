class Log {
  late String id;
  late String activity;
  late String activity_type_id;
  late String date;

  Log(String id, String activity, String activity_type_id, String date) {
    this.id = id;
    this.activity = activity;
    this.activity_type_id = activity_type_id;
    this.date = date;
  }

  Log.fromJson(Map json)
      : id = json['id'],
        activity = json['activity_log'],
        activity_type_id = json['activity_type_id'],
        date = json['date_created'];

  Map toJson() {
    return {
      'id': id,
      'activity_log': activity,
      'activity_type_id': activity_type_id,
      'date_created': date
    };
  }
}
