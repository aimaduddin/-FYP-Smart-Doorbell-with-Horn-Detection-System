class Audio {
  late String id;
  late String name;
  late String title;
  late String date;

  Audio(String id, String name, String title, String date) {
    this.id = id;
    this.name = name;
    this.title = title;
    this.date = date;
  }

  Audio.fromJson(Map json)
      : id = json['id'],
        name = json['name'],
        title = json['title'],
        date = json['date_created'];

  Map toJson() {
    return {'id': id, 'name': name, 'title': title, 'date': date};
  }
}
