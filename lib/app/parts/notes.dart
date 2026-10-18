part of '../../main.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class SavedNote {
  final String subject;
  final double td;
  final double tp;
  final double exam;
  final double moy;
  final double coef;
  final double cred;

  SavedNote({
    required this.subject,
    required this.td,
    required this.tp,
    required this.exam,
    required this.moy,
    required this.coef,
    required this.cred,
  });
}

class NotesStorage {
  static List<SavedNote> savedNotes = [];
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();
  final _notes = <_NoteModel>[
    _NoteModel('خطة مذاكرة S1', 'رياضيات، فيزياء، برمجة...', pinned: true, isExample: true),
  ];
  final _archived = <_NoteModel>[];

  void _create() async {
    final res = await showModalBottomSheet<_NoteModel>(
      isScrollControlled: true,
      context: context,
      builder: (_) => const _NoteEditor(),
    );
    if (res != null) setState(() => _notes.insert(0, res));
  }

  void _edit(_NoteModel m) async {
    final res = await showModalBottomSheet<_NoteModel>(
      isScrollControlled: true,
      context: context,
      builder: (_) => _NoteEditor(initial: m),
    );
    if (res != null) {
      setState(() {
        final i = _notes.indexOf(m);
        if (i != -1) _notes[i] = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final pinned =
    _notes.where((e) => e.pinned && (q.isEmpty || e.match(q))).toList();
    final others =
    _notes.where((e) => !e.pinned && (q.isEmpty || e.match(q))).toList();
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: TextDirection.ltr,
          //mainAxisSize: MainAxisSize.min,
          children: [
            Row(textDirection: TextDirection.ltr, children: [
              // IconButton(
              //   icon: const Icon(Icons.menu),
              //   onPressed: () {
              //     Scaffold.of(context).openEndDrawer(); // لأنك تستخدم endDrawer
              //   },
              // ),
              Text(
                mainText(context, 'NotePade'),
                style: GoogleFonts.pacifico(
                  textStyle: Theme.of(context).textTheme.displayLarge,
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]),
            IconButton(
                onPressed: _create, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
        //   Text('NotePade',
        //   style: GoogleFonts.pacifico(textStyle: Theme.of(context).textTheme.displayLarge,
        //   fontSize: 30,
        //   fontWeight: FontWeight.w500,
        //   fontStyle: FontStyle.italic,
        //   //color: AppTeal.main[900],
        // ),),
        //leading: _DrawerLeading(showBack: canPop),
        //leadingWidth: canPop ? 96 : null,
        // actions: [
        //   IconButton(onPressed: _create, icon: const Icon(Icons.add_circle_outline)),
        // ],
      ),
      // endDrawer: const AppEndDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: S.of(context).searchClipboard,
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          if (pinned.isNotEmpty) ...[
            Text(S.of(context).pinned,
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...pinned.map((n) => _NoteTile(
              note: n,
              onTap: () => _edit(n),
              onPin: () => setState(() => n.pinned = !n.pinned),
              onArchive: () => setState(() {
                _notes.remove(n);
                _archived.add(n);
              }),
            )),
            const SizedBox(height: 10),
          ],
          if (others.isNotEmpty) ...[
            Text(S.of(context).otherNotes,
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...others.map((n) => _NoteTile(
              note: n,
              onTap: () => _edit(n),
              onPin: () => setState(() => n.pinned = !n.pinned),
              onArchive: () => setState(() {
                _notes.remove(n);
                _archived.add(n);
              }),
            )),
          ] else if (pinned.isEmpty)
            EmptyState(
                icon: Icons.note_alt_outlined, title: S.of(context).noNotesYet),
          const SizedBox(height: 12),
          if (_archived.isNotEmpty) ...[
            const Divider(),
            Text(S.of(context).archive,
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ..._archived.map((n) => _NoteTile(
              note: n,
              archived: true,
              onTap: () {},
              onPin: null,
              onArchive: () => setState(() {
                _archived.remove(n);
                _notes.add(n);
              }),
            )),
          ],
        ],
      ),
    );
  }
}

class _NoteModel {
  String title;
  String body;
  bool pinned;
  final bool isExample;
  _NoteModel(this.title, this.body, {this.pinned = false, this.isExample = false});
  bool match(String q) =>
      title.toLowerCase().contains(q) || body.toLowerCase().contains(q);
}

class _NoteTile extends StatelessWidget {
  final _NoteModel note;
  final bool archived;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  const _NoteTile(
      {required this.note,
        this.archived = false,
        this.onTap,
        this.onPin,
        this.onArchive});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kNoteYellow.withValues(alpha:
      Theme.of(context).brightness == Brightness.dark ? .12 : .35),
      child: ListTile(
        title: Text(note.isExample ? mainText(context, note.title) : note.title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(note.isExample ? mainText(context, note.body) : note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: onTap,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (onPin != null)
            IconButton(
                onPressed: onPin,
                icon: Icon(
                    note.pinned ? Icons.push_pin : Icons.push_pin_outlined)),
          if (onArchive != null)
            IconButton(
                onPressed: onArchive,
                icon:
                Icon(archived ? Icons.unarchive : Icons.archive_outlined)),
        ]),
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final _NoteModel? initial;
  const _NoteEditor({this.initial});
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _t;
  late final TextEditingController _b;
  bool _pin = false;

  @override
  void initState() {
    super.initState();
    _t = TextEditingController(text: widget.initial?.isExample == true ? mainTextCurrent(widget.initial!.title) : widget.initial?.title ?? '');
    _b = TextEditingController(text: widget.initial?.isExample == true ? mainTextCurrent(widget.initial!.body) : widget.initial?.body ?? '');
    _pin = widget.initial?.pinned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).note,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _t,
                decoration: InputDecoration(labelText: S.of(context).title),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _b,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(labelText: S.of(context).content),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _pin,
                onChanged: (v) => setState(() => _pin = v ?? false),
                title: Text(S.of(context).pinNote),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  if (_t.text.trim().isEmpty && _b.text.trim().isEmpty) {
                    Navigator.pop(context);
                    return;
                  }
                  Navigator.pop(context,
                      _NoteModel(_t.text.trim(), _b.text.trim(), pinned: _pin));
                },
                icon: const Icon(Icons.save_outlined),
                label: Text(S.of(context).save),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Notes — واجهة الجامعة احترافية (إنشاء/بحث/تثبيت/أرشفة)
// ============================================================================

