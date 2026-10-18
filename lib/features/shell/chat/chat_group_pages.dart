import 'dart:async';
import 'package:flutter/services.dart';
import 'new_conversation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../l10n/chat_group_strings.dart';
import '../../../services/chat_group_service.dart';
import '../../../services/community_search_text.dart';

mixin _GroupOwner<T extends StatefulWidget> on State<T> {
  final _ownerGuard = ChatGroupOwnerGuard(
      currentUid: () => FirebaseAuth.instance.currentUser?.uid);
  StreamSubscription<User?>? _ownerSubscription;
  bool get _hasOwner => _ownerGuard.isCurrent;
  @override
  void initState() {
    super.initState();
    _ownerSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) {
      _ownerGuard.observe(user?.uid);
      if (mounted && !_hasOwner) {
        _clearOwnerData();
        setState(() {});
      }
    });
  }

  void _clearOwnerData() {}
  @override
  void dispose() {
    _ownerSubscription?.cancel();
    super.dispose();
  }
}

class CreateChatGroupPage extends StatefulWidget {
  const CreateChatGroupPage({super.key});
  @override
  State<CreateChatGroupPage> createState() => _CreateChatGroupPageState();
}

class _CreateChatGroupPageState extends State<CreateChatGroupPage>
    with _GroupOwner<CreateChatGroupPage> {
  final _name = TextEditingController();
  final _selected = <String, String>{};
  final _service = ChatGroupService();
  final _id =
      'group_${FirebaseFirestore.instance.collection('chats').doc().id}';
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  String? _submittedName;
  List<String>? _submittedMembers;
  bool _busy = false;
  Object? _error;
  bool _invalidName = false;
  bool _created = false;
  int _sent = 0;
  @override
  void _clearOwnerData() {
    _created = false;
    _sent = 0;
    _selected.clear();
    _submittedMembers = null;
    _submittedName = null;
    _name.clear();
    _error = null;
  }

  Future<void> _searchPerson() async {
    if (!_hasOwner || _busy || _submittedName != null) return;
    final person = await Navigator.of(context).push<ChatContact>(
        MaterialPageRoute(builder: (_) => const NewConversationPage()));
    if (!mounted || !_hasOwner || person == null || person.id == _uid) return;
    {
      setState(() => _selected[person.id] = person.name);
    }
  }

  Future<void> _create() async {
    if (_busy || !_hasOwner) return;
    if (_name.text.trim().isEmpty || _name.text.trim().length > 80) {
      setState(() => _invalidName = true);
      return;
    }
    _submittedName ??= _name.text.trim();
    _submittedMembers ??= List<String>.unmodifiable(_selected.keys);
    setState(() {
      _busy = true;
      _error = null;
      _invalidName = false;
    });
    try {
      final id = await _service.create(
          groupId: _id,
          name: _submittedName!,
          memberIds: _submittedMembers!,
          onProgress: (sent, total) {
            if (mounted && _hasOwner)
              setState(() {
                _created = true;
                _sent = sent;
              });
          });
      if (mounted && _hasOwner) Navigator.of(context).pop(id);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = _submittedName != null;
    if (!_hasOwner) {
      return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(chatGroupText(context, 'Sign in again'))));
    }
    return Scaffold(
      appBar: AppBar(title: Text(chatGroupText(context, 'New group'))),
      body: ChatGroupFormLayout(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                  controller: _name,
                  enabled: !locked,
                  maxLength: 80,
                  decoration: InputDecoration(
                      labelText: chatGroupText(context, 'Group name'),
                      errorText: _invalidName
                          ? chatGroupText(context, 'Name required')
                          : null,
                      border: const OutlineInputBorder())),
              Text(chatGroupText(context, 'Invitations explanation')),
              Text(chatGroupText(
                  context, 'Joining gives access to existing group messages.')),
              const SizedBox(height: 8),
              Text(
                  '${chatGroupText(context, 'Members')}: ${_selected.length + 1}'),
              if (_selected.isNotEmpty)
                SizedBox(
                    height: 48,
                    child:
                        ListView(scrollDirection: Axis.horizontal, children: [
                      for (final entry in _selected.entries)
                        Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: InputChip(
                                label: Text(entry.value),
                                onDeleted: locked
                                    ? null
                                    : () => setState(
                                        () => _selected.remove(entry.key)))),
                    ])),
              if (locked && !_busy && !_created)
                Text(chatGroupText(context, 'Submission locked')),
              if (_created) ...[
                Text(chatGroupText(context, 'Invitations sent') +
                    ': $_sent/' +
                    (_submittedMembers?.length ?? 0).toString()),
                if (!_busy && _error != null) ...[
                  Text(chatGroupText(
                      context, 'Group created; invitations pending')),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(_id),
                      child: Text(chatGroupText(context, 'Open group'))),
                ],
              ],
              if (_error != null) _GroupError(error: _error!),
            ])),
        TextButton.icon(
            onPressed: locked ? null : _searchPerson,
            icon: const Icon(Icons.person_search_outlined),
            label: Text(chatGroupText(context, 'Find people'))),
        SizedBox(
            height: 320,
            child: _PeerSelector(
                excluded: {_uid!},
                selected: _selected.keys.toSet(),
                enabled: !locked,
                onSelect: (id, name) => setState(() {
                      if (_selected.containsKey(id)) {
                        _selected.remove(id);
                      } else {
                        _selected[id] = name;
                      }
                    }))),
        Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _busy ? null : _create,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(chatGroupText(context,
                            _error == null ? 'Create group' : 'Retry'))))),
      ]),
    );
  }
}

/// Contact suggestions use only conversations already readable by this member.
class _PeerSelector extends StatefulWidget {
  const _PeerSelector(
      {required this.excluded,
      required this.selected,
      required this.onSelect,
      this.enabled = true});
  final Set<String> excluded, selected;
  final bool enabled;
  final void Function(String id, String name) onSelect;
  @override
  State<_PeerSelector> createState() => _PeerSelectorState();
}

class _PeerSelectorState extends State<_PeerSelector>
    with _GroupOwner<_PeerSelector> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  final _search = TextEditingController();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    if (_uid != null) {
      _stream = FirebaseFirestore.instance
          .collection('chats')
          .where('memberIds', arrayContains: _uid)
          .snapshots();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: chatGroupText(context, 'Search people'),
                    border: const OutlineInputBorder()))),
        Text(chatGroupText(context, 'Choose existing contacts'),
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (!_hasOwner) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: TextButton(
                            onPressed: () => setState(_listen),
                            child: Text(chatGroupText(context, 'Retry'))));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final peers = <String, String>{};
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data();
                    if (data['type'] == 'group') continue;
                    final ids = data['memberIds'];
                    final members = data['members'];
                    if (ids is! List || members is! Map) continue;
                    for (final id in ids.whereType<String>()) {
                      if (id == _uid || widget.excluded.contains(id)) continue;
                      final member = members[id];
                      final name = member is Map
                          ? (member['name'] ?? '').toString().trim()
                          : '';
                      peers[id] = name.isEmpty
                          ? chatGroupText(context, 'Member')
                          : name;
                    }
                  }
                  final query = normalizeCommunitySearch(_search.text);
                  final items = peers.entries
                      .where((row) =>
                          normalizeCommunitySearch(row.value).contains(query))
                      .toList()
                    ..sort((a, b) => a.value.compareTo(b.value));
                  if (items.isEmpty) {
                    return Center(
                        child:
                            Text(chatGroupText(context, 'No contacts found')));
                  }
                  return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final peer = items[index];
                        return CheckboxListTile(
                            value: widget.selected.contains(peer.key),
                            title: Text(peer.value),
                            secondary: const CircleAvatar(
                                child: Icon(Icons.person_outline)),
                            onChanged: widget.enabled
                                ? (_) => widget.onSelect(peer.key, peer.value)
                                : null);
                      });
                })),
      ]);
}

class ChatGroupDetailsPage extends StatefulWidget {
  const ChatGroupDetailsPage(
      {super.key, required this.chatId, this.onStarredMessages});
  final VoidCallback? onStarredMessages;
  final String chatId;
  @override
  State<ChatGroupDetailsPage> createState() => _ChatGroupDetailsPageState();
}

class _ChatGroupDetailsPageState extends State<ChatGroupDetailsPage>
    with _GroupOwner<ChatGroupDetailsPage> {
  final _service = ChatGroupService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  late final _stream = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .snapshots();
  bool _busy = false;
  Object? _error;
  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(chatGroupText(context, title)),
                  content: Text(chatGroupText(context, message)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(chatGroupText(context, 'Cancel'))),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(chatGroupText(context, 'Confirm'))),
                  ])) ??
      false;
  Future<void> _run(String action, {String? memberId, String? name}) async {
    if (_busy || !_hasOwner) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.manage(
          chatId: widget.chatId,
          action: action,
          memberId: memberId,
          name: name);
      if (!mounted || !_hasOwner) return;
      if (action == 'leave') {
        Navigator.pop(context, true);
      } else if (action == 'invite') {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(chatGroupText(context, 'Invitation sent'))));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(String name) async {
    final result = await showDialog<String>(
        context: context, builder: (_) => ChatGroupNameDialog(name: name));
    if (mounted && result != null) await _run('rename', name: result);
  }

  Future<void> _invite(Set<String> members) async {
    if (!_hasOwner || _busy) return;
    final person = await Navigator.of(context).push<ChatContact>(
        MaterialPageRoute(builder: (_) => const NewConversationPage()));
    if (!mounted || !_hasOwner || person == null) return;
    if (members.contains(person.id)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(chatGroupText(context, 'Already a member or invited'))));
      return;
    }
    await _run('invite', memberId: person.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(chatGroupText(context, 'Group details'))),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (!_hasOwner) {
                return Center(
                    child: Text(chatGroupText(context, 'Sign in again')));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text(chatGroupText(context, 'Loading failed')));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!.data();
              final ids =
                  (data?['memberIds'] as List?)?.whereType<String>().toList() ??
                      [];
              if (data == null || !ids.contains(_uid)) {
                return Center(
                    child: Text(chatGroupText(context, 'No longer a member')));
              }
              final admins =
                  (data['adminIds'] as List?)?.whereType<String>().toSet() ??
                      <String>{};
              final pendingIds = (data['pendingMemberIds'] as List?)
                      ?.whereType<String>()
                      .toList() ??
                  <String>[];
              final pendingMembers = data['pendingMembers'] is Map
                  ? data['pendingMembers'] as Map
                  : const {};
              final isAdmin = admins.contains(_uid);
              final lastAdmin = isAdmin && admins.length == 1 && ids.length > 1;
              final name = (data['name'] ?? '').toString();
              final members =
                  data['members'] is Map ? data['members'] as Map : const {};
              return ListView(padding: const EdgeInsets.all(16), children: [
                const CircleAvatar(
                    radius: 36, child: Icon(Icons.groups_outlined, size: 36)),
                const SizedBox(height: 12),
                if (widget.onStarredMessages != null)
                  Material(
                      color: Colors.transparent,
                      child: ListTile(
                          leading: const Icon(Icons.star_outline),
                          title:
                              Text(chatGroupText(context, 'Starred messages')),
                          onTap: widget.onStarredMessages)),
                Text(name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('${chatGroupText(context, 'Members')}: ${ids.length}',
                    textAlign: TextAlign.center),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) _GroupError(error: _error!),
                if (isAdmin)
                  TextButton.icon(icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(chatGroupText(context, 'Group access')),
                    onPressed: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatGroupAccessPage(chatId: widget.chatId,
                        adminsOnly: data['adminsOnlyMessaging'] == true)))),
                if (isAdmin)
                  Wrap(spacing: 8, children: [
                    TextButton.icon(
                        onPressed: _busy ? null : () => _rename(name),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(chatGroupText(context, 'Rename group'))),
                    TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _invite({...ids, ...pendingIds}),
                        icon: const Icon(Icons.person_add_outlined),
                        label: Text(chatGroupText(context, 'Invite member'))),
                  ]),
                const Divider(),
                for (final id in ids)
                  Builder(builder: (context) {
                    final brief = members[id];
                    final memberName =
                        brief is Map ? (brief['name'] ?? '').toString() : '';
                    return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.person_outline)),
                        title: Text(id == _uid
                            ? chatGroupText(context, 'You')
                            : memberName.isEmpty
                                ? chatGroupText(context, 'Member')
                                : memberName),
                        subtitle: Text(chatGroupText(
                            context, admins.contains(id) ? 'Admin' : 'Member')),
                        trailing: !isAdmin || _busy
                            ? null
                            : PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'remove' &&
                                      !await _confirm('Remove member',
                                          'Remove confirmation')) {
                                    return;
                                  }
                                  if (mounted) await _run(action, memberId: id);
                                },
                                itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: admins.contains(id)
                                              ? 'demote'
                                              : 'promote',
                                          child: Text(chatGroupText(
                                              context,
                                              admins.contains(id)
                                                  ? 'Remove admin'
                                                  : 'Make admin'))),
                                      if (id != _uid)
                                        PopupMenuItem(
                                            value: 'remove',
                                            child: Text(chatGroupText(
                                                context, 'Remove member'))),
                                    ]));
                  }),
                if (isAdmin && pendingIds.isNotEmpty) ...[
                  const Divider(),
                  Text(chatGroupText(context, 'Pending invitations'),
                      style: Theme.of(context).textTheme.titleMedium),
                  for (final id in pendingIds)
                    Builder(builder: (context) {
                      final brief = pendingMembers[id];
                      final pendingName = brief is Map
                          ? (brief['name'] ?? '').toString().trim()
                          : '';
                      return ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text(pendingName.isEmpty
                              ? chatGroupText(context, 'Member')
                              : pendingName),
                          subtitle: Text(
                              chatGroupText(context, 'Invitation pending')),
                          trailing: IconButton(
                              tooltip:
                                  chatGroupText(context, 'Cancel invitation'),
                              onPressed: _busy
                                  ? null
                                  : () => _run('remove', memberId: id),
                              icon: const Icon(Icons.close)));
                    }),
                ],
                const Divider(),
                if (lastAdmin)
                  Text(chatGroupText(
                      context, 'Promote another admin before leaving.')),
                TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await _confirm(
                                    'Leave group', 'Leave confirmation') &&
                                mounted) {
                              await _run('leave');
                            }
                          },
                    icon: const Icon(Icons.logout),
                    label: Text(chatGroupText(context, 'Leave group'))),
              ]);
            }),
      );
}

class ChatGroupInvitations extends StatefulWidget {
  const ChatGroupInvitations({super.key, required this.onOpen});
  final void Function(String chatId, String name) onOpen;
  @override
  State<ChatGroupInvitations> createState() => _ChatGroupInvitationsState();
}

class _ChatGroupInvitationsState extends State<ChatGroupInvitations>
    with _GroupOwner<ChatGroupInvitations> {
  final _service = ChatGroupService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  final _pending = <String>{};
  final _errors = <String, Object>{};
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    if (_uid != null) {
      _stream = FirebaseFirestore.instance
          .collection('groupInvites')
          .where('receiverId', isEqualTo: _uid)
          .where('status', isEqualTo: 'pending')
          .snapshots();
    }
  }

  Future<void> _respond(String chatId, String name, bool accept) async {
    if (_pending.contains(chatId) || !_hasOwner) return;
    setState(() {
      _pending.add(chatId);
      _errors.remove(chatId);
    });
    try {
      await _service.respond(chatId: chatId, accept: accept);
      if (mounted && _hasOwner && accept) widget.onOpen(chatId, name);
    } catch (error) {
      if (mounted) setState(() => _errors[chatId] = error);
    } finally {
      if (mounted) setState(() => _pending.remove(chatId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasOwner) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TextButton(
                onPressed: () => setState(_listen),
                child: Text(
                    '${chatGroupText(context, 'Group invitations')} · ${chatGroupText(context, 'Retry')}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          return Material(
              color: Colors.transparent,
              child: ExpansionTile(
                  title: Text(
                      '${chatGroupText(context, 'Group invitations')} (${snapshot.data!.docs.length})'),
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(chatGroupText(context,
                            'Joining gives access to existing group messages.'))),
                    ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: ListView(shrinkWrap: true, children: [
                          for (final doc in snapshot.data!.docs)
                            Builder(builder: (context) {
                              final data = doc.data();
                              final id = data['chatId'];
                              final name = (data['groupName'] ?? '').toString();
                              if (id is! String) return const SizedBox.shrink();
                              return ListTile(
                                  leading: const CircleAvatar(
                                      child: Icon(Icons.group_add_outlined)),
                                  title: Text(name),
                                  subtitle: _errors[id] == null
                                      ? null
                                      : Text(chatGroupError(
                                          context, _errors[id]!)),
                                  trailing: _pending.contains(id)
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                              IconButton(
                                                  tooltip: chatGroupText(
                                                      context, 'Accept'),
                                                  onPressed: () =>
                                                      _respond(id, name, true),
                                                  icon:
                                                      const Icon(Icons.check)),
                                              IconButton(
                                                  tooltip: chatGroupText(
                                                      context, 'Decline'),
                                                  onPressed: () =>
                                                      _respond(id, name, false),
                                                  icon:
                                                      const Icon(Icons.close)),
                                            ]));
                            }),
                        ])),
                  ]));
        });
  }
}

class _GroupError extends StatelessWidget {
  const _GroupError({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(chatGroupError(context, error),
          style: TextStyle(color: Theme.of(context).colorScheme.error)));
}

/// Owns the controller for the full lifetime of the animated dialog route.
class ChatGroupNameDialog extends StatefulWidget {
  const ChatGroupNameDialog({super.key, required this.name});
  final String name;
  @override
  State<ChatGroupNameDialog> createState() => _ChatGroupNameDialogState();
}

class _ChatGroupNameDialogState extends State<ChatGroupNameDialog> {
  late final _controller = TextEditingController(text: widget.name);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(chatGroupText(context, 'Rename group')),
          content: TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 80,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: chatGroupText(context, 'Group name'))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(chatGroupText(context, 'Cancel'))),
            FilledButton(
                onPressed: _controller.text.trim().isEmpty ||
                        _controller.text.trim().length > 80
                    ? null
                    : () => Navigator.pop(context, _controller.text.trim()),
                child: Text(chatGroupText(context, 'Save'))),
          ]);
}

/// The entire form scrolls when a keyboard or a small screen reduces its height.
class ChatGroupFormLayout extends StatelessWidget {
  const ChatGroupFormLayout({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(children: children)));
}

/// Links request admission; they never grant access to conversation messages.
class ChatGroupJoinPage extends StatefulWidget {
  const ChatGroupJoinPage({super.key, this.initialLink = ''});
  final String initialLink;
  @override
  State<ChatGroupJoinPage> createState() => _ChatGroupJoinPageState();
}

class _ChatGroupJoinPageState extends State<ChatGroupJoinPage>
    with _GroupOwner<ChatGroupJoinPage> {
  final _service = ChatGroupService();
  late final _link = TextEditingController(text: widget.initialLink);
  bool _busy = false;
  String? _status;
  Object? _error;
  @override
  void _clearOwnerData() { _link.clear(); _status = null; _error = null; }
  @override
  void dispose() { _link.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (_busy || !_hasOwner) return;
    setState(() { _busy = true; _error = null; _status = null; });
    try {
      final status = await _service.requestJoin(_link.text);
      if (mounted && _hasOwner) setState(() => _status = status);
    } catch (error) { if (mounted && _hasOwner) setState(() => _error = error); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(chatGroupText(context, 'Join by invitation link'))),
    body: ChatGroupFormLayout(children: [Padding(padding: const EdgeInsets.all(16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(chatGroupText(context, 'Join request explanation')),
        const SizedBox(height: 12),
        TextField(controller: _link, enabled: _hasOwner && !_busy,
          keyboardType: TextInputType.url, autocorrect: false, enableSuggestions: false,
          decoration: InputDecoration(labelText: chatGroupText(context, 'Invitation link'), border: const OutlineInputBorder())),
        if (!_hasOwner) Text(chatGroupText(context, 'Sign in again')),
        if (_error != null) _GroupError(error: _error!),
        if (_status != null) Text(chatGroupText(context, _status == 'open' ? 'Already a member' : 'Join request sent')),
        const SizedBox(height: 12),
        FilledButton(onPressed: !_hasOwner || _busy ? null : _submit,
          child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(chatGroupText(context, 'Request to join'))),
      ]))]));
}

class ChatGroupAccessPage extends StatefulWidget {
  const ChatGroupAccessPage({super.key, required this.chatId, required this.adminsOnly});
  final String chatId;
  final bool adminsOnly;
  @override
  State<ChatGroupAccessPage> createState() => _ChatGroupAccessPageState();
}

class _ChatGroupAccessPageState extends State<ChatGroupAccessPage>
    with _GroupOwner<ChatGroupAccessPage> {
  final _service = ChatGroupService();
  late bool _adminsOnly = widget.adminsOnly;
  bool _showingLink = false;
  bool _busy = false;
  Object? _error;
  List<Map<String, dynamic>> _requests = [];
  @override
  void initState() { super.initState(); _reload(); }
  @override
  void _clearOwnerData() {
    _requests = []; _error = null;
    if (_showingLink && mounted) { _showingLink = false; Navigator.of(context, rootNavigator: true).pop(); }
  }
  Future<void> _reload() async {
    if (_busy || !_hasOwner) return;
    setState(() { _busy = true; _error = null; });
    try {
      final requests = await _service.joinRequests(widget.chatId);
      if (mounted && _hasOwner) setState(() => _requests = requests);
    } catch (error) { if (mounted && _hasOwner) setState(() => _error = error); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _setting(String action, {bool? value}) async {
    if (_busy || !_hasOwner) return;
    if (action == 'rotateLink' || action == 'revokeLink') {
      final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        content: Text(chatGroupText(context, 'Link change confirmation')),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(chatGroupText(context, 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(chatGroupText(context, 'Confirm')))]));
      if (confirmed != true || !mounted || !_hasOwner) return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final result = await _service.access(chatId: widget.chatId, action: action, adminsOnly: value);
      if (!mounted || !_hasOwner) return;
      if (action == 'setMessaging') setState(() => _adminsOnly = result['adminsOnly'] == true);
      if (action == 'rotateLink') {
        final link = result['link'];
        if (link is! String || link.isEmpty) throw StateError('Missing group link');
        _showingLink = true;
        await showDialog<void>(context: context, builder: (context) => AlertDialog(
          title: Text(chatGroupText(context, 'Invitation link')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(chatGroupText(context, 'Link expires in seven days')), const SizedBox(height: 8), SelectableText(link)]),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(chatGroupText(context, 'Cancel'))),
            FilledButton(onPressed: () async { if (!_hasOwner) return; await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) Navigator.pop(context); }, child: Text(chatGroupText(context, 'Copy link')))]));
        _showingLink = false;
      } else if (action == 'revokeLink') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chatGroupText(context, 'Invitation link revoked'))));
      }
    } catch (error) { if (mounted && _hasOwner) setState(() => _error = error); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _review(String uid, bool approve) async {
    if (_busy || !_hasOwner) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _service.reviewJoin(chatId: widget.chatId, requesterId: uid, approve: approve);
      final requests = await _service.joinRequests(widget.chatId);
      if (mounted && _hasOwner) setState(() => _requests = requests);
    } catch (error) { if (mounted && _hasOwner) setState(() => _error = error); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(chatGroupText(context, 'Group access'))),
    body: !_hasOwner ? Center(child: Text(chatGroupText(context, 'Sign in again'))) : ListView(padding: const EdgeInsets.all(16), children: [
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) _GroupError(error: _error!),
      SwitchListTile(title: Text(chatGroupText(context, 'Only admins can send messages')),
        value: _adminsOnly, onChanged: _busy ? null : (value) => _setting('setMessaging', value: value)),
      Text(chatGroupText(context, 'Join request explanation')),
      TextButton.icon(onPressed: _busy ? null : () => _setting('rotateLink'), icon: const Icon(Icons.link), label: Text(chatGroupText(context, 'Create new invitation link'))),
      TextButton.icon(onPressed: _busy ? null : () => _setting('revokeLink'), icon: const Icon(Icons.link_off), label: Text(chatGroupText(context, 'Revoke invitation link'))),
      const Divider(),
      Row(children: [Expanded(child: Text(chatGroupText(context, 'Join requests'))),
        IconButton(onPressed: _busy ? null : _reload, tooltip: chatGroupText(context, 'Refresh'), icon: const Icon(Icons.refresh))]),
      if (!_busy && _requests.isEmpty) Text(chatGroupText(context, 'No pending join requests')),
      for (final request in _requests) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text((request['name'] as String?)?.isNotEmpty == true ? request['name'] as String : chatGroupText(context, 'Member')),
        Wrap(spacing: 8, children: [TextButton(onPressed: _busy ? null : () => _review(request['uid'] as String, false), child: Text(chatGroupText(context, 'Reject'))),
          FilledButton(onPressed: _busy ? null : () => _review(request['uid'] as String, true), child: Text(chatGroupText(context, 'Approve')))])]))),
      if (_requests.length >= 50) Text(chatGroupText(context, 'More requests after reviewing this page')),
    ]));
}
