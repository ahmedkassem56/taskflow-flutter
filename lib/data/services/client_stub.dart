import 'package:http/http.dart' as http;

/// Web fallback: the browser owns connection management (fetch), so the
/// default client is correct — keep-alive/stale-socket issues cannot occur.
http.Client createPlatformClient() => http.Client();
