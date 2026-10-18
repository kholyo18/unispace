part of '../../main.dart';

enum _PollSlideType { text, image, video, poll }
enum LinearScaleStyle { numbers, line, emoji, emoji1, stars, slider }

class _PollSlide {
  final _PollSlideType type;
  final String? text;
  final Uint8List? imageBytes;
  final File? videoFile;
  final VideoPlayerController? videoController;
  final PollData? poll;

  _PollSlide.text(this.text)
      : type = _PollSlideType.text,
        imageBytes = null,
        videoFile = null,
        videoController = null,
        poll = null;

  _PollSlide.image(this.imageBytes)
      : type = _PollSlideType.image,
        text = null,
        videoFile = null,
        videoController = null,
        poll = null;

  _PollSlide.video(this.videoFile, this.videoController)
      : type = _PollSlideType.video,
        text = null,
        imageBytes = null,
        poll = null;

  _PollSlide.poll(this.poll)
      : type = _PollSlideType.poll,
        text = null,
        imageBytes = null,
        videoFile = null,
        videoController = null;
}

class _EmojiThumbShape extends SliderComponentShape {
  final String emoji;
  final double size;

  const _EmojiThumbShape({required this.emoji, this.size = 36});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(size, size);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter? labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final painter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size * 0.85),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      center.dx - painter.width / 2,
      center.dy - painter.height / 2,
    );
    painter.paint(context.canvas, offset);
  }
}
enum DateRestrictMode { months, days, ranges }

class _BuilderItem {
  final PostBlock? block;
  final PollQuestion? poll;

  _BuilderItem.block(this.block) : poll = null;
  _BuilderItem.poll(this.poll) : block = null;

  bool get isBlock => block != null;
}

//=======================================================
class PollDateConfig {
  final int year;
  final List<int> months;           // الوضع القديم
  final List<DateTime> allowedDays; // أيام محددة (يوم/شهر/سنة)
  final bool includeTime;
  final bool multiSelect;// أكثر من يوم
  final String? rangesText;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;


  PollDateConfig({
    required this.year,
    this.months = const [],
    this.allowedDays = const [],
    this.includeTime = false,
    this.multiSelect = false,
    this.rangeStart,
    this.rangesText,
    this.rangeEnd,
  });

  bool get hasSpecificDays => allowedDays.isNotEmpty;
  bool get hasRange => rangeStart != null && rangeEnd != null;
}

class PollData {
  final String question;
  final PollQuestionType type;
  final List<String> options;
  final List<String> gridRows;
  final List<String> gridColumns;
  final LinearScaleStyle? scaleStyle;
  final int? scaleSize;
  final PollDateConfig? dateConfig;
  final TimeOfDay? selectedTime;
  final bool isRequired;
  final String scaleMinLabel;
  final String scaleMaxLabel;
  final bool includeTime;
  final bool multiSelect; // ← أضف هذا

  PollData({
    required this.question,
    required this.type,
    this.options = const [],
    this.gridRows = const [],
    this.gridColumns = const [],
    this.scaleStyle,
    this.scaleSize,
    this.dateConfig,
    this.selectedTime,
    this.isRequired = false,
    this.scaleMinLabel = 'Low',
    this.scaleMaxLabel = 'High',
    this.includeTime = false,
    this.multiSelect = false,
  });

  factory PollData.fromQuestion(PollQuestion q) {
    return PollData(
      question: q.questionCtrl.text.trim(),
      type: q.type,
      options: q.options
          .map((c) => c.text.trim())
          .where((o) => o.isNotEmpty)
          .toList(),
      gridRows: List.from(q.gridRows),
      gridColumns: List.from(q.gridColumns),
      scaleStyle: q.scaleStyle,
      scaleSize: q.scaleSize,
      dateConfig: q.dateConfig,
      includeTime: q.includeTime,
      multiSelect: q.dateConfig?.multiSelect ?? q.multiSelectDate,
      selectedTime: q.selectedTime,
      isRequired: q.confirmed,
      scaleMinLabel: q.scaleMinLabel.isEmpty ? 'Low' : q.scaleMinLabel,
      scaleMaxLabel: q.scaleMaxLabel.isEmpty ? 'High' : q.scaleMaxLabel,
    );
  }
}

enum PollQuestionType {
  shortText,
  longText,
  checkbox,
  linearScale,
  dropdown,
  singelOptin,
  grid,
  checkboxGrid,
  date,
  time,
}

class PollQuestion {
  PollQuestionType type;
  double previewSliderValue = 50;
  bool includeTime = false;
  bool multiSelectDate = false;
  TextEditingController? rangesCtrl;
  DateRestrictMode dateMode = DateRestrictMode.months;
  final scaleMinCtrl = TextEditingController(text: 'Low');
  final scaleMaxCtrl = TextEditingController(text: 'High');

  String get scaleMinLabel => scaleMinCtrl.text.trim();
  String get scaleMaxLabel => scaleMaxCtrl.text.trim();

// أضفه داخل class PollQuestion
  factory PollQuestion.fromPollData(PollData data) {
    final q = PollQuestion(data.type);
    q.questionCtrl.text = data.question;
    q.includeTime = data.includeTime;
    q.confirmed = data.isRequired;
    q.multiSelectDate = data.multiSelect;
    if (data.dateConfig != null) {
      q.dateConfig = data.dateConfig;
    }
    // options
    if (data.dateConfig != null) {
      q.dateConfig = data.dateConfig;
      final t = data.dateConfig!.rangesText?.trim() ?? '';
      if (t.isNotEmpty) {
        q.dateMode = DateRestrictMode.ranges;
      } else if (data.dateConfig!.allowedDays.isNotEmpty) {
        q.dateMode = DateRestrictMode.days;
      } else {
        q.dateMode = DateRestrictMode.months;
      }
    }
    q.multiSelectDate = data.multiSelect;


    // grid
    if (data.gridRows.isNotEmpty) {
      q.gridRows = List.from(data.gridRows);
      q.gridColumns = List.from(data.gridColumns);
      q.gridConfirmed = true;
      q.initGrid();
    }

    // linearScale
    if (data.scaleStyle != null) {
      q.scaleStyle = data.scaleStyle!;
      q.scaleSize = data.scaleSize ?? 5;
      q.scaleConfirmed = true;
    }

    // date
    if (data.dateConfig != null) {
      q.dateConfig = data.dateConfig;
    }

    // time
    if (data.selectedTime != null) {
      q.selectedTime = data.selectedTime;
      q.timeController ??= TextEditingController();
    }
    q.scaleMinCtrl.text = data.scaleMinLabel;
    q.scaleMaxCtrl.text = data.scaleMaxLabel;
    q.scaleSize = data.scaleSize ?? 5;
    q.scaleStyle = data.scaleStyle ?? LinearScaleStyle.numbers;

    return q;
  }
  // ===== عام =====
  TextEditingController questionCtrl = TextEditingController();
  bool confirmed = false;
  Key rebuildKey = UniqueKey();

  // ===== Options (checkbox / radio / dropdown) =====
  List<TextEditingController> options = [];
  List<bool> selectedOptions = []; // checkbox + multiple
  int? selectedOptionIndex;        // radio + dropdown

  // ===== Grid / CheckboxGrid =====
  List<String> gridRows = [];
  List<String> gridColumns = [];
  List<List<bool>> gridSelections = [];
  bool gridConfirmed = false;

  // ===== Date =====
  PollDateConfig? dateConfig;

  // ===== Linear Scale =====
  LinearScaleStyle scaleStyle;
  int scaleSize;
  bool scaleConfirmed;

  int? selectedNumber;
  int lineValue;
  int? selectedEmoji;
  int? selectedEmoji1;

  // ===== Time =====
  TextEditingController? timeController;
  TimeOfDay? selectedTime;

  // ================= CONSTRUCTOR =================

  PollQuestion(this.type)
      : scaleStyle = LinearScaleStyle.numbers,
        scaleSize = 5,
        scaleConfirmed = false,
        lineValue = 1 {
    if (_needsOptions(type)) {
      options = [
        TextEditingController(),
        TextEditingController(),
      ];

      selectedOptions = List.filled(options.length, false);
    }

    if (type == PollQuestionType.time) {
      timeController = TextEditingController();
    }
  }

  // ================= GRID INIT =================

  void initGrid() {
    if (gridRows.isNotEmpty && gridColumns.isNotEmpty) {
      gridSelections = List.generate(
        gridRows.length,
            (_) => List.filled(gridColumns.length, false),
      );
    }
  }

  // ================= RESET (UNDO) =================

  void reset() {
    confirmed = false;
    rebuildKey = UniqueKey();

    switch (type) {
      case PollQuestionType.linearScale:
        scaleConfirmed = false;
        selectedNumber = null;
        selectedEmoji = null;
        selectedEmoji1 = null;
        lineValue = 1;
        break;

      case PollQuestionType.grid:
      case PollQuestionType.checkboxGrid:
        gridConfirmed = false;
        initGrid();
        break;

      case PollQuestionType.checkbox:
      case PollQuestionType.singelOptin:
        selectedOptions = List.filled(options.length, false);
        break;

      case PollQuestionType.dropdown:
        selectedOptionIndex = null;
        break;

      case PollQuestionType.time:
        selectedTime = null;
        timeController?.clear();
        break;

      case PollQuestionType.date:
        dateConfig = null;
        break;

      default:
        break;
    }
  }

  // ================= HELPERS =================

  static bool _needsOptions(PollQuestionType type) {
    return const [
      PollQuestionType.checkbox,
      PollQuestionType.dropdown,
      PollQuestionType.singelOptin,
      PollQuestionType.grid,
      PollQuestionType.checkboxGrid,
    ].contains(type);
  }
}

