part of dart_force_client_lib;

class ForceClient extends ForceBaseMessageSendReceiver with ClientSendable {
  static const Duration RECONNECT_DELAY = const Duration(milliseconds: 500);
  
  bool _connectPending = false;
  WebSocket webSocket;
  
  StreamController<ForceConnectEvent> _connectController;
  
  ForceMessageDispatcher _messageDispatcher;
  
  String wsPath;
  
  var _profileInfo = {};
  
  ForceClient({wsPath: "/ws"}) {
    _connectController = new StreamController<ForceConnectEvent>();
    _messageDispatcher = new ForceMessageDispatcher(this);
    this.wsPath = wsPath;
  }
  
  void connect() {
    _connectPending = false;
    _connectController = new StreamController<ForceConnectEvent>();
    webSocket = new WebSocket('ws://${Uri.base.host}:${Uri.base.port}$wsPath');
    webSocket.onOpen.first.then((_) {
      onConnected();
      webSocket.onClose.first.then((_) {
        print("Connection disconnected to ${webSocket.url}");
        onDisconnected();
      });
    });
    webSocket.onError.first.then((_) {
      print("Failed to connect to ${webSocket.url}. "
            "Please run bin/server.dart and try again.");
      onDisconnected();
    });
  }
  
  void onConnected() {
    print("connected!");
    _connectController.add(new ForceConnectEvent("connected"));
    webSocket.onMessage.listen((e) {
      _messageDispatcher.onMessageDispatch(onInnerMessage(e.data));
    });
  }
  
  void onDisconnected() {
    print("disconnected!");
    _connectController.add(new ForceConnectEvent("disconnected"));
    if (_connectPending) return;
    _connectPending = true;
    new Timer(RECONNECT_DELAY, connect);
  }
  
  void on(String request, MessageReceiver vaderMessageController) {
    _messageDispatcher.register(request, vaderMessageController);
  }
   
  Stream<ForceConnectEvent> get onConnecting => _connectController.stream;
}