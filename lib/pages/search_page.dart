import 'package:chatapp/helper/helper_functions.dart';
import 'package:chatapp/pages/chat_page.dart';
import 'package:chatapp/service/database_service.dart';
import 'package:chatapp/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _isLoading = false;
  bool _hasUserSearched = false;
  bool _isJoined = false;
  String _userName = '';
  User? _user;
  QuerySnapshot? _searchSnapshot;
  final _searchEC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUserIdAndName();
  }

  @override
  void dispose() {
    _searchEC.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserIdAndName() async {
    await HelperFunctions.getUserNameFromSF().then((value) {
      if (value != null) {
        setState(() {
          _userName = value;
        });
      }
    });
    _user = FirebaseAuth.instance.currentUser;
  }

  String _getName(String res) {
    return res.substring(res.indexOf('_') + 1);
  }

  // String _getId(String res) {
  //   return res.substring(0, res.indexOf('_'));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Pesquisar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchEC,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Pesquisar grupos...',
                      hintStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _initSearchMethod();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : _groupList(),
        ],
      ),
    );
  }

  Future<void> _initSearchMethod() async {
    if (_searchEC.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      await DatabaseService().searchByName(_searchEC.text).then((snapshot) {
        setState(() {
          _searchSnapshot = snapshot;
          _isLoading = false;
          _hasUserSearched = true;
        });
      });
    }
  }

  _groupList() {
    return _hasUserSearched
        ? ListView.builder(
            shrinkWrap: true,
            itemCount: _searchSnapshot!.docs.length,
            itemBuilder: (context, index) {
              return _groupTile(
                _userName,
                _searchSnapshot!.docs[index]['groupId'],
                _searchSnapshot!.docs[index]['groupName'],
                _searchSnapshot!.docs[index]['admin'],
              );
            },
          )
        : Container();
  }

  Widget _groupTile(
      String userName, String groupId, String groupName, String admin) {
    _joinedOrNot(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        groupName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('Admin: ${_getName(admin)}'),
      trailing: InkWell(
        onTap: () async {
          await DatabaseService(uid: _user!.uid)
              .toggleGroupJoin(groupId, userName, groupName);

          if (_isJoined) {
            setState(() {
              _isJoined = !_isJoined;
            });
            // ignore: use_build_context_synchronously
            showSnackBar(context, Colors.green, 'Você entrou no grupo');
            Future.delayed(const Duration(seconds: 2), () {
              nextScreen(
                context,
                ChatPage(
                    groupId: groupId, groupName: groupName, userName: userName),
              );
            });
          } else {
            setState(() {
              _isJoined = !_isJoined;
              showSnackBar(
                  context, Colors.red, 'Você saiu do grupo $groupName');
            });
          }
        },
        child: _isJoined
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: const Text(
                  'Participante',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text(
                  'Participar',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _joinedOrNot(
      String userName, String groupId, String groupName, String admin) async {
    await DatabaseService(uid: _user!.uid)
        .isUserJoined(groupName, groupId, userName)
        .then((value) {
      setState(() {
        _isJoined = value;
      });
    });
  }
}
