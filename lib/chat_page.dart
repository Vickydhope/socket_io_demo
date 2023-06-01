import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:socket_io_demo/extensions/time_extensions.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int unreadMessageCount = 0;

  late Socket socket;
  TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    connectToServer();

    _scrollController.addListener(() {
      if(_scrollController.position.maxScrollExtent <= _scrollController.offset){
        setState(() {
          unreadMessageCount = 0;
        });
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Socket.IO Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              controller: _scrollController,
              reverse: false,
              padding: const EdgeInsets.all(8),
              separatorBuilder: (context, index) => const SizedBox(
                height: 10,
              ),
              itemCount: messages.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  padding: const EdgeInsets.only(
                      left: 14, right: 14, top: 10, bottom: 10),
                  child: Column(
                    crossAxisAlignment: socket.id != messages[index]['id']
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          socket.id != messages[index]['id']
                              ? Container()
                              : Expanded(flex: 1, child: Container()),
                          Expanded(
                            flex: 5,
                            child: Align(
                              alignment: socket.id != messages[index]['id']
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomRight:
                                        socket.id != messages[index]['id']
                                            ? const Radius.circular(20)
                                            : const Radius.circular(3),
                                    bottomLeft:
                                        socket.id != messages[index]['id']
                                            ? const Radius.circular(3)
                                            : const Radius.circular(20),
                                  ),
                                  color: socket.id != messages[index]['id']
                                      ? Colors.grey.shade800
                                      : Colors.green,
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    /* if (image != null) ...{
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ImageFullScreenWrapperWidget(
                                          child: Image.asset(image),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                    },*/
                                    Text(
                                      "${messages[index]['message']}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (socket.id != messages[index]['id'])
                            Expanded(flex: 1, child: Container()),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0)
                            .copyWith(top: 4),
                        child: Timeago(
                          builder: (BuildContext context, String value) =>
                              Text(value),
                          date: (messages[index]['timestamp'] as int).toDate,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (unreadMessageCount > 0) ...{
            Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                  onTap: () {
                    setState(() {
                      unreadMessageCount = 0;
                    });
                    scrollToEnd();
                  },
                  child:
                      Text("You have $unreadMessageCount unread message(s).")),
            )
          },
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0)
                  .copyWith(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            if (messageController.text.isNotEmpty) {
                              sendMessage(messageController.text.trim());
                              messageController.clear();
                            }
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100)),
                        hintText: 'Type your message here...',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void connectToServer() {
    try {
      // Configure socket transports must be specified
      socket = io('http://127.0.0.1:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // Connect to websocket
      socket.connect();

      // Handle socket events
      socket.on('connect', (_) => print('connect: ${socket.id}'));
      socket.on(
        'location',
        (data) => handleLocationListen,
      );
      socket.on('typing', (_) => handleTyping);
      socket.on('message', (_) {
        print("object");
        return handleMessage(_);
      });
      socket.on('disconnect', (_) => print('disconnect'));
      socket.on('fromServer', (_) => print(_));
    } catch (e) {
      print(e.toString());
    }
  }

  // Send Location to Server
  sendLocation(Map<String, dynamic> data) {
    socket.emit("location", data);
  }

  // Listen to Location updates of connected users from server
  handleLocationListen(Map<String, dynamic> data) async {
    print(data);
  }

  // Send update of user's typing status
  sendTyping(bool typing) {
    socket.emit("typing", {
      "id": socket.id,
      "typing": typing,
    });
  }

  // Listen to update of typing status from connected users
  void handleTyping(Map<String, dynamic> data) {
    print(data);
  }

  // Send a Message to the server
  sendMessage(String message) {
    socket.emit(
      "message",
      {
        "id": socket.id,
        "message": message, // Message to be sent
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      },
    );
    scrollToEnd();
  }

  // Listen to all message events from connected users
  handleMessage(Map<String, dynamic> data) async {
    setState(() {
      messages.add(data);
    });

    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent -
            MediaQuery.of(context).size.height * 0.10) {
      scrollToEnd();
    } else {
      setState(() {
        unreadMessageCount++;
      });
    }
  }

  scrollToEnd() async {
    await Future.delayed(const Duration(milliseconds: 80));

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }
}
