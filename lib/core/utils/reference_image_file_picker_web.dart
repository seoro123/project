// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

class PickedReferenceImage {
  const PickedReferenceImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

Future<PickedReferenceImage?> pickReferenceImageFile() async {
  final completer = Completer<PickedReferenceImage?>();
  final input = html.FileUploadInputElement()
    ..accept =
        'image/png,image/jpeg,image/webp,image/gif,.png,.jpg,.jpeg,.webp,.gif'
    ..multiple = false;
  input.style.display = 'none';

  // 웹에서는 숨겨진 input을 DOM에 붙여 두는 편이 파일 선택/읽기 흐름이 안정적이다.
  html.document.body?.append(input);

  void completeOnce(PickedReferenceImage? value) {
    input.remove();
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  void completeErrorOnce(Object error) {
    input.remove();
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  }

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completeOnce(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();
    reader.onError.first.then((_) {
      completeErrorOnce(StateError('선택한 이미지 파일을 읽지 못했습니다.'));
    });
    reader.onLoad.first.then((_) async {
      final dataUrl = reader.result;
      if (dataUrl is! String || dataUrl.isEmpty) {
        completeErrorOnce(StateError('선택한 이미지 파일을 읽을 수 없습니다.'));
        return;
      }
      try {
        final bytes = await _normalizeImageDataUrlToPngBytes(dataUrl);
        if (bytes.isEmpty) {
          completeErrorOnce(StateError('선택한 이미지 파일을 읽을 수 없습니다.'));
          return;
        }
        completeOnce(
          PickedReferenceImage(bytes: bytes, name: 'reference-image.png'),
        );
      } catch (_) {
        completeErrorOnce(
          StateError(
            '이미지를 PNG로 변환하지 못했습니다. JPG, PNG, WebP, GIF 파일로 다시 시도해 주세요.',
          ),
        );
      }
    });
    reader.readAsDataUrl(file);
  });

  input.click();
  return completer.future;
}

Future<Uint8List> _normalizeImageDataUrlToPngBytes(String dataUrl) async {
  final completer = Completer<Uint8List>();
  final image = html.ImageElement();

  image.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('이미지를 불러오지 못했습니다.'));
    }
  });

  image.onLoad.first.then((_) {
    if (completer.isCompleted) {
      return;
    }
    final width = image.naturalWidth;
    final height = image.naturalHeight;
    if (width <= 0 || height <= 0) {
      completer.completeError(StateError('이미지 크기를 확인하지 못했습니다.'));
      return;
    }

    final canvas = html.CanvasElement(width: width, height: height);
    canvas.context2D.drawImage(image, 0, 0);
    final pngDataUrl = canvas.toDataUrl('image/png');
    final bytes = _bytesFromDataUrl(pngDataUrl);
    if (bytes == null || bytes.isEmpty) {
      completer.completeError(StateError('PNG 변환에 실패했습니다.'));
      return;
    }
    completer.complete(bytes);
  });

  image.src = dataUrl;
  return completer.future;
}

Uint8List? _bytesFromDataUrl(String dataUrl) {
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex == -1 || commaIndex == dataUrl.length - 1) {
    return null;
  }
  return Uint8List.fromList(base64Decode(dataUrl.substring(commaIndex + 1)));
}
