// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_retell_ai_suppression.dart';

const _tracerName = 'dartastic_otel_libs_retell_ai';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class RetellAiResult {
  const RetellAiResult({
    this.callId,
    this.agentId,
    this.agentVersion,
    this.llmWebsocketUrl,
    this.callType,
    this.callStatus,
    this.disconnectionReason,
    this.durationMs,
    this.userSentiment,
    this.callSuccessful,
    this.endCallAfterSilenceMs,
    this.combinedCost,
    this.retellLlmLatencyP50,
    this.e2eLatencyP50,
    this.statusCode,
  });

  final String? callId;
  final String? agentId;

  /// Retell auto-bumps an agent version on each update; useful for
  /// correlating performance to config changes.
  final String? agentVersion;

  /// `null` when using Retell's built-in LLM, else the customer's
  /// websocket endpoint URL.
  final String? llmWebsocketUrl;

  /// `web_call` / `phone_call`.
  final String? callType;

  /// `registered` / `not_connected` / `ongoing` / `ended` / `error`.
  final String? callStatus;

  /// `user_hangup` / `agent_hangup` / `call_transfer` /
  /// `voicemail_reached` / `inactivity` / `max_duration_reached` /
  /// `concurrency_limit_reached` / `dial_busy` / `dial_failed` /
  /// `dial_no_answer` / `error_llm_websocket_open` /
  /// `error_llm_websocket_lost_connection` / `error_frontend` /
  /// `error_unknown`.
  final String? disconnectionReason;

  final int? durationMs;

  /// `Positive` / `Neutral` / `Negative` / `Unknown` — Retell's
  /// post-call sentiment analysis.
  final String? userSentiment;

  /// `true` if the agent's success-criteria prompt fired.
  final bool? callSuccessful;

  /// Configured silence-disconnect threshold.
  final int? endCallAfterSilenceMs;

  /// Combined cost in USD (Retell's pricing summary across providers).
  final double? combinedCost;

  /// Retell's internal LLM latency p50 (ms) — when not using a custom
  /// LLM websocket.
  final int? retellLlmLatencyP50;

  /// End-to-end latency p50 (ms) — user-speech-end to agent-speech-
  /// start.
  final int? e2eLatencyP50;

  final int? statusCode;
}

class RetellAiCallResult<T> {
  const RetellAiCallResult({required this.value, this.result});
  final T value;
  final RetellAiResult? result;
}

/// Wraps a Retell AI API call in a CLIENT span. [operation] is one of
/// `call.create_phone`, `call.create_web`, `call.list`, `call.get`,
/// `call.end`, `agent.create`, `agent.update`, `phone_number.create`,
/// `phone_number.import`, `voice.list`, `knowledge_base.create`.
Future<T> tracedRetellAi<T>({
  required String operation,
  required Future<RetellAiCallResult<T>> Function() invoke,
}) async {
  if (retellAiInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'retell_ai',
    'rpc.method': operation,
    'retell_ai.operation': operation,
  };

  final span = _tracer().startSpan(
    'retell_ai $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.callId != null) {
        extras.add(OTel.attributeString(
          'retell_ai.call.id',
          r.result!.callId!,
        ));
      }
      if (r.result!.agentId != null) {
        extras.add(OTel.attributeString(
          'retell_ai.agent.id',
          r.result!.agentId!,
        ));
      }
      if (r.result!.agentVersion != null) {
        extras.add(OTel.attributeString(
          'retell_ai.agent.version',
          r.result!.agentVersion!,
        ));
      }
      if (r.result!.llmWebsocketUrl != null) {
        extras.add(OTel.attributeString(
          'retell_ai.llm.websocket_url',
          r.result!.llmWebsocketUrl!,
        ));
      }
      if (r.result!.callType != null) {
        extras.add(OTel.attributeString(
          'retell_ai.call.type',
          r.result!.callType!,
        ));
      }
      if (r.result!.callStatus != null) {
        extras.add(OTel.attributeString(
          'retell_ai.call.status',
          r.result!.callStatus!,
        ));
        if (r.result!.callStatus == 'error') {
          span.setStatus(SpanStatusCode.Error, 'Retell call.status error');
        }
      }
      if (r.result!.disconnectionReason != null) {
        extras.add(OTel.attributeString(
          'retell_ai.disconnection.reason',
          r.result!.disconnectionReason!,
        ));
        if (r.result!.disconnectionReason!.startsWith('error_') ||
            r.result!.disconnectionReason == 'concurrency_limit_reached') {
          span.setStatus(
            SpanStatusCode.Error,
            'Retell disconnection ${r.result!.disconnectionReason}',
          );
        }
      }
      if (r.result!.durationMs != null) {
        extras.add(OTel.attributeInt(
          'retell_ai.duration_ms',
          r.result!.durationMs!,
        ));
      }
      if (r.result!.userSentiment != null) {
        extras.add(OTel.attributeString(
          'retell_ai.user.sentiment',
          r.result!.userSentiment!,
        ));
      }
      if (r.result!.callSuccessful != null) {
        extras.add(OTel.attributeBool(
          'retell_ai.call.successful',
          r.result!.callSuccessful!,
        ));
      }
      if (r.result!.endCallAfterSilenceMs != null) {
        extras.add(OTel.attributeInt(
          'retell_ai.silence.threshold_ms',
          r.result!.endCallAfterSilenceMs!,
        ));
      }
      if (r.result!.combinedCost != null) {
        extras.add(OTel.attributeDouble(
          'retell_ai.cost.combined_usd',
          r.result!.combinedCost!,
        ));
      }
      if (r.result!.retellLlmLatencyP50 != null) {
        extras.add(OTel.attributeInt(
          'retell_ai.llm.latency_p50_ms',
          r.result!.retellLlmLatencyP50!,
        ));
      }
      if (r.result!.e2eLatencyP50 != null) {
        extras.add(OTel.attributeInt(
          'retell_ai.e2e.latency_p50_ms',
          r.result!.e2eLatencyP50!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Retell HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
