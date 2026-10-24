import 'package:flutter/material.dart';
import '../../../l10n/chat_group_strings.dart';
import '../../../l10n/chat_compose_strings.dart';
import 'new_conversation_page.dart';
import 'chat_profile_avatar.dart';

/// Selection stays on one screen; the caller owns submission and identity.
class ChatGroupCreationForm extends StatefulWidget {
  const ChatGroupCreationForm(
      {super.key,
      required this.search,
      required this.nameController,
      required this.selected,
      required this.onToggle,
      required this.suggestions,
      required this.onCreate,
      required this.locked,
      required this.busy,
      required this.retry,
      required this.status});
  final ChatContactSearchController search;
  final TextEditingController nameController;
  final Map<String, ChatContact> selected;
  final ValueChanged<ChatContact> onToggle;
  final Widget suggestions, status;
  final VoidCallback onCreate;
  final bool locked, busy, retry;
  @override
  State<ChatGroupCreationForm> createState() => _ChatGroupCreationFormState();
}

class _ChatGroupCreationFormState extends State<ChatGroupCreationForm> {
  final _query = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.search.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.search.removeListener(_refresh);
    _query.dispose();
    super.dispose();
  }

  Future<void> _details() async {
    final value = await showDialog<String>(
        context: context,
        builder: (_) => _GroupSetupDialog(
            name: widget.nameController.text, locked: widget.locked));
    if (!mounted || widget.locked || value == null) return;
    setState(() => widget.nameController.text = value);
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => chatGroupText(context, key);
    final colors = Theme.of(context).colorScheme;
    final submit = SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            onPressed: widget.busy ? null : widget.onCreate,
            child: widget.busy
                ? SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, semanticsLabel: t('Create group')))
                : Text(
                    '${t(widget.retry ? 'Retry' : 'Create group')}${widget.selected.isEmpty ? '' : ' (${widget.selected.length})'}'),
          ),
        ));
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.nameController.text.trim().isEmpty
                  ? t('New group')
                  : widget.nameController.text.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
                tooltip: t('Group details'),
                onPressed: _details,
                icon: const Icon(Icons.tune_rounded)),
          ]),
      body: SafeArea(
          bottom: false,
          child: Column(children: [
            if (!widget.locked)
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _query,
                    maxLength: 160,
                    onChanged: widget.search.updateQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                        counterText: '',
                        hintText: t('Search people'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: chatComposeText(context, 'clear'),
                                onPressed: () {
                                  _query.clear();
                                  widget.search.updateQuery('');
                                },
                                icon: const Icon(Icons.close))),
                  )),
            if (widget.selected.isNotEmpty)
              SizedBox(
                  height: 44 + MediaQuery.textScalerOf(context).scale(18),
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final person in widget.selected.values)
                          Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: Center(
                                  child: InputChip(
                                avatar: ChatProfileAvatar(
                                    name: person.name,
                                    photoUrl: person.photoUrl),
                                label: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 160),
                                    child: Text(person.name,
                                        overflow: TextOverflow.ellipsis)),
                                onDeleted: widget.locked
                                    ? null
                                    : () => widget.onToggle(person),
                                deleteButtonTooltipMessage:
                                    '${t('Remove selection')}: ${person.name}',
                              ))),
                      ])),
            const Divider(height: 1),
            Expanded(
                child: widget.locked
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: [widget.status])
                    : Builder(builder: (context) {
                        final search = widget.search;
                        if (search.query.isEmpty) return widget.suggestions;
                        if (search.loading)
                          return const Center(
                              child: CircularProgressIndicator());
                        if (search.errorKey != null)
                          return Center(
                              child: SingleChildScrollView(
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                Text(chatComposeText(context, search.errorKey!),
                                    textAlign: TextAlign.center),
                                if (search.errorKey != 'unauthenticated')
                                  TextButton(
                                      onPressed: () =>
                                          search.updateQuery(_query.text),
                                      child: Text(t('Retry'))),
                              ])));
                        if (search.people.isEmpty)
                          return Center(child: Text(t('No contacts found')));
                        return ListView.builder(
                            itemCount: search.people.length +
                                (search.truncated ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == search.people.length)
                                return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                        chatComposeText(context, 'truncated')));
                              final person = search.people[index];
                              final selected =
                                  widget.selected.containsKey(person.id);
                              return ListTile(
                                key: ValueKey('group-person-${person.id}'),
                                leading: ChatProfileAvatar(
                                    name: person.name,
                                    photoUrl: person.photoUrl),
                                title: Text(person.name),
                                subtitle: person.username == null
                                    ? null
                                    : Text(
                                        '@${person.username!.replaceFirst(RegExp(r'^@'), '')}'),
                                trailing: Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: selected
                                        ? colors.primary
                                        : colors.outline),
                                selected: selected,
                                onTap: () {
                                  if (search.canSelect(person))
                                    widget.onToggle(person);
                                },
                              );
                            });
                      })),
            submit,
          ])),
    );
  }
}

class _GroupSetupDialog extends StatefulWidget {
  const _GroupSetupDialog({required this.name, required this.locked});
  final String name;
  final bool locked;
  @override
  State<_GroupSetupDialog> createState() => _GroupSetupDialogState();
}

class _GroupSetupDialogState extends State<_GroupSetupDialog> {
  late final _edit = TextEditingController(text: widget.name);
  @override
  void dispose() {
    _edit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(chatGroupText(context, 'Group details')),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: _edit,
                  onChanged: (_) => setState(() {}),
                  maxLength: 80,
                  enabled: !widget.locked,
                  decoration: InputDecoration(
                      labelText:
                          chatGroupText(context, 'Group name (optional)'))),
              Text(chatGroupText(context, 'People are added directly when their privacy settings allow it. They can leave the group.')),
              const SizedBox(height: 12),
              Text(chatGroupText(
                  context, 'Joining gives access to existing group messages.')),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(chatGroupText(context, 'Cancel'))),
          FilledButton(
              onPressed: _edit.text.trim().length > 80
                  ? null
                  : () => Navigator.pop(context, _edit.text.trim()),
              child: Text(chatGroupText(context, 'Save')))
        ],
      );
}
