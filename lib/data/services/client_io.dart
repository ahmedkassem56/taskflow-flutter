import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

/// Platform HTTP client (mobile/desktop). The dart:io default idle timeout is
/// 15s — far longer than the server's keep-alive — so a pooled connection can
/// be half-dead (server already closed it) when a mutation reuses it, and the
/// POST stalls for seconds (the "sometimes instant, sometimes few seconds"
/// add delay on Android). A 3s idle timeout means connections are only reused
/// for request bursts; anything after a real gap rides a fresh socket
/// (negligible cost on LAN).
http.Client createPlatformClient() {
  final HttpClient raw = HttpClient()
    ..idleTimeout = const Duration(seconds: 3)
    ..connectionTimeout = const Duration(seconds: 5);
  return http_io.IOClient(raw);
}
