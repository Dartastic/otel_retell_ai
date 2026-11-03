// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_retell_ai/otel_retell_ai.dart';

/// Traces Retell AI calls with OpenTelemetry.
///
/// `otel_retell_ai` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Retell AI call in
/// [tracedRetellAi]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'retell-ai-example');

  // Wraps a Retell AI API call in a CLIENT span.
  final retellAiId = await tracedRetellAi<String>(
    operation: 'call.create_phone',
    invoke: () async {
      // Make the Retell AI call here, then report what it returned.
      const id = 'retell_ai_8f3a2c';
      return const RetellAiCallResult(
          value: id,
          result: RetellAiResult(
              callId: 'call_8f3a2c',
              agentId: 'agent_8f3a2c',
              agentVersion: '1',
              llmWebsocketUrl: 'null',
              callType: 'web_call',
              callStatus: 'registered',
              disconnectionReason: 'user_hangup',
              durationMs: 120,
              userSentiment: 'Positive',
              callSuccessful: true,
              endCallAfterSilenceMs: 120,
              combinedCost: 0.5,
              retellLlmLatencyP50: 120,
              e2eLatencyP50: 120,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedRetellAi call.create_phone returned $retellAiId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutRetellAiInstrumentationAsync.
  await runWithoutRetellAiInstrumentationAsync(
    () => tracedRetellAi<String>(
      operation: 'call.create_phone',
      invoke: () async {
        const id = 'retell_ai_8f3a2c';
        return const RetellAiCallResult(
            value: id,
            result: RetellAiResult(
                callId: 'call_8f3a2c',
                agentId: 'agent_8f3a2c',
                agentVersion: '1',
                llmWebsocketUrl: 'null',
                callType: 'web_call',
                callStatus: 'registered',
                disconnectionReason: 'user_hangup',
                durationMs: 120,
                userSentiment: 'Positive',
                callSuccessful: true,
                endCallAfterSilenceMs: 120,
                combinedCost: 0.5,
                retellLlmLatencyP50: 120,
                e2eLatencyP50: 120,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
