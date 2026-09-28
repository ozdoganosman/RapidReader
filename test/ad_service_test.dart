import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart' show instanceManager;
import 'package:rapid_reader/core/services/ad_service.dart';

class _FakeConsent implements ConsentInformation {
  _FakeConsent({required this.updates, required this.canRequest, this.privacyOptions = false});

  final bool updates;
  final bool canRequest;
  final bool privacyOptions;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) =>
      updates ? successListener() : failureListener(FormError(errorCode: 2, message: 'offline'));

  @override
  Future<bool> canRequestAds() async => canRequest;

  @override
  Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus() async =>
      privacyOptions ? PrivacyOptionsRequirementStatus.required : PrivacyOptionsRequirementStatus.notRequired;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final original = ConsentInformation.instance;
  late List<String> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_mobile_ads/ump', StandardMethodCodec()),
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      calls.add(call.method);
      return call.method == 'MobileAds#initialize' ? InitializationStatus({}) : null;
    });
  });

  tearDown(() => ConsentInformation.instance = original);

  test('asks for consent first and requests no ads until it is given', () async {
    ConsentInformation.instance = _FakeConsent(updates: true, canRequest: false);
    final ads = AdService.test();
    await ads.initialize();

    expect(await ads.ready, isFalse);
    expect(calls, ['UserMessagingPlatform#loadAndShowConsentFormIfRequired']);
  });

  test('offline it goes on with the choice of an earlier start', () async {
    ConsentInformation.instance = _FakeConsent(updates: false, canRequest: true);
    final ads = AdService.test();
    await ads.initialize();

    expect(await ads.ready, isTrue);
    expect(calls, isNot(contains('UserMessagingPlatform#loadAndShowConsentFormIfRequired')));
    expect(calls, contains('MobileAds#initialize'));
  });

  test('the settings offer to change the consent only where it is required', () async {
    ConsentInformation.instance = _FakeConsent(updates: true, canRequest: true, privacyOptions: true);
    final ads = AdService.test();
    await ads.initialize();
    expect(await ads.privacyOptionsRequired(), isTrue);

    ConsentInformation.instance = _FakeConsent(updates: true, canRequest: true);
    expect(await ads.privacyOptionsRequired(), isFalse);
  });
}
