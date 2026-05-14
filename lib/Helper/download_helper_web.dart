import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> saveFile(List<int> bytes, String fileName) async {
  final uint8List = Uint8List.fromList(bytes);
  final jsArray = uint8List.toJS;                    // ✅ Uint8List pe toJS kaam karta hai
  final blob = web.Blob(
    [jsArray].toJS,
    web.BlobPropertyBag(
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
  );
  final url = web.URL.createObjectURL(blob);
  (web.document.createElement('a') as web.HTMLAnchorElement)
    ..href = url
    ..setAttribute('download', fileName)
    ..click();
  web.URL.revokeObjectURL(url);
}