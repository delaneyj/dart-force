part of dart_force_server_lib;

class BasicServer {
  
  final Logger log = new Logger('BasicServer');
  
  Router router;
  String startPage = 'index.html';
  
  var wsPath;
  var port;
  var buildDir;
  var virDir;
  var bind_address = InternetAddress.ANY_IP_V6;
  
  PollingServer pollingServer;
  
  BasicServer(this.wsPath, {port: 8080, host: null, buildPath: '../build' }) {
    this.port = port;
    if (host!=null) {
      this.bind_address = host;
    }
    buildDir = Platform.script.resolve(buildPath).toFilePath();
    if (!new Directory(buildDir).existsSync()) {
      log.severe("The 'build/' directory was not found. Please run 'pub build'.");
      return;
    } 
  }
  
  Future start(WebSocketHandler handleWs) {
    Completer completer = new Completer.sync();
    HttpServer.bind(bind_address, port).then((server) { 
        _onStart(server, handleWs);
        completer.complete(const []);
      });
    return completer.future;
  }
  
  void _onStart(server, WebSocketHandler handleWs) {
      log.info("Search server is running on "
          "'http://${Platform.localHostname}:$port/'");
      router = new Router(server);

      // The client will connect using a WebSocket. Upgrade requests to '/ws' and
      // forward them to 'handleWebSocket'.
      router.serve(this.wsPath)
        .transform(new WebSocketTransformer())
          .listen((WebSocket ws) {
            handleWs(new WebSocketWrapper(ws));
          });
      
      // long_polling();
      pollingServer = new PollingServer(router, wsPath);
      pollingServer.onConnection.listen((PollingSocket socket) {
        handleWs(socket);
      });
      
      // Set up default handler. This will serve files from our 'build' directory.
      virDir = new http_server.VirtualDirectory(buildDir);
      // Disable jail-root, as packages are local sym-links.
      virDir.jailRoot = false;
      virDir.allowDirectoryListing = true;
      virDir.directoryHandler = (dir, request) {
        // Redirect directory-requests to index.html files.
        var indexUri = new Uri.file(dir.path).resolve(startPage);
        virDir.serveFile(new File(indexUri.toFilePath()), request);
      };

      // Add an error page handler.
      virDir.errorPageHandler = (HttpRequest request) {
        log.warning("Resource not found ${request.uri.path}");
        request.response.statusCode = HttpStatus.NOT_FOUND;
        request.response.close();
      };

      // Serve everything not routed elsewhere through the virtual directory.
      virDir.serve(router.defaultStream);
  }
  
}