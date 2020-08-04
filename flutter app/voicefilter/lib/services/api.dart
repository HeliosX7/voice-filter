import 'package:http/http.dart' as http;
import 'dart:convert';

String postUrl = "< API KEY >";

Future<void> runVoiceFilterBackend(
  String userId,
  String timeId,
  String input,
  String ref,
) async {
  Map data = {
    'user_id': userId,
    'time_id': timeId,
    'input_url': input,
    'ref_url': ref,
  };

  //encode Map to JSON
  var body = json.encode(data);
  var response = await http.post(
    postUrl,
    body: body,
  );
  print("${response.statusCode}");
}
