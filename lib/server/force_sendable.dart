part of dart_force_server_lib;

class Sendable implements Sender {

 final Logger log = new Logger('Sendable');
  
  Map<String, Socket> webSockets;
  Map<String, dynamic> profiles;
  
  void send(request, data) {
    printAmountOfConnections();
    
    var sendingPackage =  {
          'request': request,
          'data': data
      };
    
    webSockets.forEach((String key, Socket ws) {
      log.info("breadcasting ... to $key");
      ws.add(JSON.encode(sendingPackage));
    });
  }
  
  void sendTo(id, request, data) {
    log.info("*** send to $id");
    Socket ws = webSockets[id];
    var sendingPackage =  {
          'request': request,
          'data': data
    };
    if (ws != null) {
      ws.add(JSON.encode(sendingPackage));
    }
  }
  
  void sendToProfile(key, value, request, data) {
    List<String> ids = new List<String>();
    profiles.forEach((String id, profile_data) {
      if (profile_data[key] == value) {
        ids.add(id);
      }
    });
    if (ids.isNotEmpty) {
      for (String id in ids) {
        sendTo(id, request, data);
      }
    }
  }
  
  void printAmountOfConnections() {
    int size = this.webSockets.length;
    log.info("*** total amount of ws $size");
  }

}