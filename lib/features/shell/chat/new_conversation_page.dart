import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/chat_compose_strings.dart';
import '../../../services/community_search_text.dart';

class ChatContact {
  const ChatContact(
      {required this.id, required this.name, this.photoUrl, this.username});
  final String id;
  final String name;
  final String? photoUrl;
  final String? username;
}

class ChatContactSearchResult {
  const ChatContactSearchResult(this.people, {this.truncated = false});
  final List<ChatContact> people;
  final bool truncated;
}

typedef ChatContactSearch = Future<ChatContactSearchResult> Function(
    String query);

/// Uses the same authorized search endpoint as community search. It never lists
/// user documents directly or caches search results across accounts.
Future<ChatContactSearchResult> searchChatContacts(String query) async {
  final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
      .httpsCallable('searchPeople')
      .call<Map<String, dynamic>>({'query': query});
  final rows = response.data['people'];
  if (rows is! List) throw const FormatException('Invalid people response');
  final people = rows.map((row) {
    if (row is! Map ||
        row['id'] is! String ||
        row['name'] is! String ||
        (row['id'] as String).isEmpty) {
      throw const FormatException('Invalid search contact');
    }
    return ChatContact(
        id: row['id'] as String,
        name: row['name'] as String,
        username: row['username'] is String ? row['username'] as String : null,
        photoUrl: row['photoUrl'] is String ? row['photoUrl'] as String : null);
  }).toList(growable: false);
  return ChatContactSearchResult(people,
      truncated: response.data['truncated'] == true);
}

class ChatContactSearchController extends ChangeNotifier {
  ChatContactSearchController(
      {required this.search,
      required this.currentUserId,
      this.debounce = const Duration(milliseconds: 450)});
  final ChatContactSearch search;
  final String? Function() currentUserId;
  final Duration debounce;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  String? _resultOwner;
  String query = '';
  bool loading = false;
  bool searched = false;
  bool truncated = false;
  String? errorKey;
  List<ChatContact> people = const [];

  void updateQuery(String value) {
    _timer?.cancel();
    final generation = ++_generation;
    query = value.trim();
    people = const [];
    _resultOwner = null;
    errorKey = null;
    searched = false;
    truncated = false;
    loading = normalizeCommunitySearch(query).isNotEmpty;
    if (loading) {
      final owner = currentUserId();
      if (owner == null) {
        loading = false;
        errorKey = 'unauthenticated';
      } else {
        _timer = Timer(debounce, () => _run(generation, owner, query));
      }
    }
    notifyListeners();
  }

  bool _current(int generation, String owner) =>
      !_disposed && generation == _generation && currentUserId() == owner;

  Future<void> _run(int generation, String owner, String requestedQuery) async {
    if (!_current(generation, owner)) return;
    try {
      final result = await search(requestedQuery);
      if (!_current(generation, owner)) return;
      final seen = <String>{};
      people = List.unmodifiable(
          result.people.where((p) => p.id != owner && seen.add(p.id)));
      truncated = result.truncated;
      _resultOwner = owner;
      searched = true;
    } on FirebaseFunctionsException catch (error) {
      if (!_current(generation, owner)) return;
      errorKey = error.code == 'unauthenticated'
          ? 'unauthenticated'
          : error.code == 'resource-exhausted'
              ? 'limited'
              : 'failed';
    } catch (_) {
      if (!_current(generation, owner)) return;
      errorKey = 'failed';
    } finally {
      if (_current(generation, owner)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  bool canSelect(ChatContact contact) =>
      !_disposed &&
      !loading &&
      _resultOwner != null &&
      currentUserId() == _resultOwner &&
      people.contains(contact);

  void accountChanged() {
    _timer?.cancel();
    _generation++;
    query = '';
    people = const [];
    _resultOwner = null;
    loading = false;
    searched = false;
    truncated = false;
    errorKey = currentUserId() == null ? 'unauthenticated' : null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key, this.controller});

  /// Optional injected controller for tests. The caller owns its lifecycle.
  final ChatContactSearchController? controller;
  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage> {
  final _text = TextEditingController();
  late final ChatContactSearchController _search;
  StreamSubscription<User?>? _authSubscription;
  @override
  void initState() {
    super.initState();
    _search = widget.controller ??
        ChatContactSearchController(
            search: searchChatContacts,
            currentUserId: () => FirebaseAuth.instance.currentUser?.uid);
    _search.addListener(_refresh);
    if (widget.controller == null) {
      var owner = FirebaseAuth.instance.currentUser?.uid;
      _authSubscription =
          FirebaseAuth.instance.authStateChanges().listen((user) {
        if (owner != user?.uid) {
          owner = user?.uid;
          _text.clear();
          _search.accountChanged();
        }
      });
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _search.removeListener(_refresh);
    if (widget.controller == null) _search.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => chatComposeText(context, key);
    return Scaffold(
      appBar: AppBar(title: Text(t('title'))),
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _text,
              autofocus: true,
              maxLength: 160,
              textInputAction: TextInputAction.search,
              onChanged: _search.updateQuery,
              decoration: InputDecoration(
                labelText: t('search'),
                counterText: '',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                suffixIcon: _text.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t('clear'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _text.clear();
                          _search.updateQuery('');
                        }),
              ),
            )),
        Expanded(
          child: _search.loading
              ? Center(
                  child:
                      CircularProgressIndicator(semanticsLabel: t('loading')))
              : _search.errorKey != null
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(t(_search.errorKey!),
                                textAlign: TextAlign.center),
                            if (_search.errorKey != 'unauthenticated')
                              TextButton(
                                  onPressed: () =>
                                      _search.updateQuery(_text.text),
                                  child: Text(t('retry'))),
                          ])))
                  : _search.people.isEmpty
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                  t(_search.searched ? 'empty' : 'start'),
                                  textAlign: TextAlign.center)))
                      : ListView.builder(
                          itemCount: _search.people.length +
                              (_search.truncated ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _search.people.length) {
                              return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(t('truncated')));
                            }
                            final person = _search.people[index];
                            final photo = Uri.tryParse(person.photoUrl ?? '');
                            return ListTile(
                              leading: ClipOval(
                                  child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: photo?.scheme == 'https'
                                          ? CachedNetworkImage(
                                              imageUrl: person.photoUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) =>
                                                  const Icon(
                                                      Icons.person_outline),
                                              errorWidget: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.person_outline))
                                          : const Icon(Icons.person_outline))),
                              title: Text(person.name.isEmpty
                                  ? (person.username ?? '')
                                  : person.name),
                              subtitle: person.username?.isNotEmpty == true
                                  ? Text(
                                      '@${person.username!.replaceFirst(RegExp(r"^@"), "")}')
                                  : null,
                              trailing: const Icon(Icons.chat_bubble_outline),
                              onTap: () {
                                if (_search.canSelect(person)) {
                                  Navigator.of(context).pop(person);
                                }
                              },
                            );
                          }),
        ),
      ])),
    );
  }
}
