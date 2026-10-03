import 'dart:io';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_test/flutter_test.dart';
import 'package:powerhr_mobile/app.dart';
import 'package:powerhr_mobile/models/backend_status.dart';
import 'package:powerhr_mobile/providers/backend_status_provider.dart';
import 'package:powerhr_mobile/services/backend_service.dart';

class RetryService extends BackendService {
  RetryService() : super(Uri.parse('https://example.invalid/'));
  int calls = 0;

  @override
  Future<BackendStatus> check() async {
    if (++calls == 1) throw const SocketException('test failure');
    return const BackendStatus(environment: 'development');
  }
}

void main() {
  testWidgets('unconfigured app starts without claiming a connection', (
    tester,
  ) async {
    await tester.pumpWidget(PowerHrApp(provider: BackendStatusProvider(null)));
    expect(find.text('PowerHR'), findsOneWidget);
    expect(find.text('Not configured'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });

  testWidgets('retry transitions from unavailable to connected', (
    tester,
  ) async {
    await tester.pumpWidget(
      PowerHrApp(provider: BackendStatusProvider(RetryService())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsOneWidget);
    await tester.tap(find.byTooltip('Check connection'));
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('development'), findsOneWidget);
  });

  testWidgets('small viewport and large text do not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(PowerHrApp(provider: BackendStatusProvider(null)));
    expect(tester.takeException(), isNull);
    expect(find.text('Not configured'), findsOneWidget);
  });
}
