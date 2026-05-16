// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_retell_ai/otel_retell_ai.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_retell_ai-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('call.create_phone records latency + sentiment + success', () async {
    await tracedRetellAi<String>(
      operation: 'call.create_phone',
      invoke: () async => const RetellAiCallResult(
        value: 'ok',
        result: RetellAiResult(
          callId: 'c_1',
          agentId: 'a_1',
          agentVersion: '12',
          llmWebsocketUrl: 'wss://customer.example.com/llm',
          callType: 'phone_call',
          callStatus: 'ended',
          disconnectionReason: 'user_hangup',
          durationMs: 132000,
          userSentiment: 'Positive',
          callSuccessful: true,
          endCallAfterSilenceMs: 10000,
          combinedCost: 0.32,
          e2eLatencyP50: 780,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('retell_ai call.create_phone')!);
    expect(a['retell_ai.agent.version'], '12');
    expect(a['retell_ai.llm.websocket_url'], 'wss://customer.example.com/llm');
    expect(a['retell_ai.disconnection.reason'], 'user_hangup');
    expect(a['retell_ai.user.sentiment'], 'Positive');
    expect(a['retell_ai.call.successful'], true);
    expect(a['retell_ai.cost.combined_usd'], 0.32);
    expect(a['retell_ai.e2e.latency_p50_ms'], 780);
  });

  test('error_llm_websocket_lost_connection sets span error', () async {
    await tracedRetellAi<String>(
      operation: 'call.get',
      invoke: () async => const RetellAiCallResult(
        value: 'ok',
        result: RetellAiResult(
          disconnectionReason: 'error_llm_websocket_lost_connection',
          durationMs: 8000,
        ),
      ),
    );
    expect(
      spans.findSpanByName('retell_ai call.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('voicemail_reached does NOT set span error', () async {
    await tracedRetellAi<String>(
      operation: 'call.get',
      invoke: () async => const RetellAiCallResult(
        value: 'ok',
        result: RetellAiResult(
          disconnectionReason: 'voicemail_reached',
        ),
      ),
    );
    expect(
      spans.findSpanByName('retell_ai call.get')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutRetellAiInstrumentationAsync(() async {
      await tracedRetellAi<String>(
        operation: 'agent.update',
        invoke: () async => const RetellAiCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('retell_ai '), isEmpty);
  });
}
