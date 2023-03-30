import 'package:chatapp/widgets/message_tile.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chatapp/pages/group_info.dart';
import 'package:chatapp/service/database_service.dart';
import 'package:chatapp/widgets/widgets.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userName;

  const ChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.userName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _admin = '';
  Stream<QuerySnapshot>? _chats;
  final _messagesEC = TextEditingController();
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    _getChatAndAdmin();
    super.initState();
  }

  @override
  void dispose() {
    _messagesEC.dispose();
    super.dispose();
  }

  void _getChatAndAdmin() {
    DatabaseService().getChats(widget.groupId).then((value) {
      setState(() {
        _chats = value;
      });
    });

    DatabaseService().getGroupAdmin(widget.groupId).then((value) {
      setState(() {
        _admin = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(widget.groupName),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(
                context,
                GroupInfo(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  adminName: _admin,
                ),
              );
            },
            icon: const Icon(Icons.info),
          ),
        ],
      ),
      body: Stack(
        children: [
          _chatMessages(),
          Container(
            alignment: Alignment.bottomCenter,
            width: MediaQuery.of(context).size.width,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              width: MediaQuery.of(context).size.width,
              color: Colors.grey[700],
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _messagesEC,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enviar uma mensagem...',
                        hintStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      _sendMessage();
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  _chatMessages() {
    return StreamBuilder(
        stream: _chats,
        builder: (context, AsyncSnapshot snapshot) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.hasClients) {
              _controller.jumpTo(_controller.position.maxScrollExtent);
            }
          });
          return snapshot.hasData
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: ListView.builder(
                    controller: _controller,
                    shrinkWrap: true,
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      return MessageTile(
                        message: snapshot.data.docs[index]['message'],
                        sender: snapshot.data.docs[index]['sender'],
                        time: snapshot.data.docs[index]['time'],
                        sentByMe: widget.userName ==
                            snapshot.data.docs[index]['sender'],
                      );
                    },
                  ),
                )
              : Container();
        });
  }

  void _sendMessage() {
    if (_messagesEC.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        'message': _messagesEC.text,
        'sender': widget.userName,
        'time': DateTime.now().microsecondsSinceEpoch,
      };

      DatabaseService().sendMessage(widget.groupId, chatMessageMap);
      setState(() {
        _messagesEC.clear();
      });
    }
  }
}
