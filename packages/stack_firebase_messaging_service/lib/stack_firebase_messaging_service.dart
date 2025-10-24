import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stack/stack.dart';

class StackFirebaseMessagingService extends Service {
  StackFirebaseMessagingService() : super(logger: Logger('StackFirebaseMessagingService'));

  @override
  Future<void> initialize() {
    $streamListen(FirebaseMessaging.instance.onTokenRefresh, _onTokenRefresh);
    return super.initialize();
  }

  late final _tokenSignal = $signal<String?>(null);
  String? get fcmToken => _tokenSignal.value;

  Future<String?> getToken() async {
    return method(
      () async {
        final token = await FirebaseMessaging.instance.getToken();
        _tokenSignal.value = token;
        return token;
      },
    );
  }

  void _onTokenRefresh(String token) {
    logger.info('FCM token refreshed');
    _tokenSignal.value = token;
  }

  Future<void> revokeToken() async {
    return method(
      () async {
        await FirebaseMessaging.instance.deleteToken();
        _tokenSignal.value = null;
      },
    );
  }
}
