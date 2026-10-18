part of '../../main.dart';

enum BlockType { text, image, video }

class PostBlock {
  final BlockType type;
  final TextEditingController? textController;
  File? image;
  File? video;
  final FocusNode? focusNode;
  VideoPlayerController? videoController;

  PostBlock.text()
      : type = BlockType.text,
        textController = TextEditingController(),
        focusNode = FocusNode(),
        image = null;

  PostBlock.image()
      : type = BlockType.image,
        textController = TextEditingController(),
        focusNode = FocusNode(),
        image = null;

  PostBlock.video()
      : type = BlockType.video,
        textController = TextEditingController(),
        focusNode = FocusNode(),
        image = null,
        video = null,
        videoController = null;
}


//=====================================================================


// ============================================================================
//                               Comments Screen
// ============================================================================

