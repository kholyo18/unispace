import 'package:flutter/material.dart';
import 'package:UniSpace/l10n/shell_strings.dart';

/// The route owns its controller until its closing animation has finished.
class ChatNicknameSheet extends StatefulWidget {
  const ChatNicknameSheet(
      {super.key, required this.initialName, required this.peerName});
  final String initialName;
  final String peerName;
  @override
  State<ChatNicknameSheet> createState() => _ChatNicknameSheetState();
}

class _ChatNicknameSheetState extends State<ChatNicknameSheet> {
  late final _controller = TextEditingController(text: widget.initialName);
  bool _submitted = false;
  void _submit(String value) {
    if (_submitted) return;
    _submitted = true;
    Navigator.of(context).pop(value.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(shellText(context, 'الاسم البديل'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(shellText(context,
                    'يغيّر الاسم المعروض عندك، ولا يغيّر اسم الحساب.')),
                const SizedBox(height: 12),
                TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                        hintText: widget.peerName,
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none)),
                    onSubmitted: _submit),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () => _submit(_controller.text),
                    child: Text(shellText(context, 'حفظ'))),
                TextButton(
                    onPressed: () => _submit(''),
                    child: Text(shellText(context, 'إزالة الاسم البديل'))),
              ]),
        ),
      );
}
