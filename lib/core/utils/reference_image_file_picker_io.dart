import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedReferenceImage {
  const PickedReferenceImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

Future<PickedReferenceImage?> pickReferenceImageFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['png', 'jpg', 'jpeg', 'webp', 'gif'],
    allowMultiple: false,
    withData: true,
    dialogTitle: '캐릭터 참고 사진 선택',
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw StateError('선택한 사진을 읽지 못했습니다. 다른 파일로 다시 시도해 주세요.');
  }

  return PickedReferenceImage(
    bytes: bytes,
    name: file.name.isNotEmpty ? file.name : 'reference-image.png',
  );
}
