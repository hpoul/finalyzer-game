import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';

final _logger = Logger('dio_firebase_performance_interceptor');

const String _EXTRA_METRIC = 'design.codeux.dart.performance.interceptor';

class FirebasePerformanceInterceptor implements Interceptor {
  FirebasePerformanceInterceptor() {}

  static const _HTTP_METHOD_MAPPING = <String, HttpMethod>{
    'POST': HttpMethod.Post,
    'GET': HttpMethod.Get,
    'Put': HttpMethod.Put,
    'OPTIONS': HttpMethod.Options,
    'HEAD': HttpMethod.Head,
  };
  final firebasePerformance = FirebasePerformance.instance;

  void _contentLength(dynamic value, void Function(int length) setter) {
    if (value == null) {
      return;
    } else if (value is int) {
      setter(value);
    } else {
      final intValue = int.tryParse(value?.toString());
      if (intValue != null) {
        setter(intValue);
      }
    }
  }

  Future<void> _stopHttpMetric(RequestOptions request, Response response) async {
    final httpMetric = request.extra.remove(_EXTRA_METRIC) as HttpMetric;
    if (httpMetric == null) {
      _logger.warning('Http metric for response was null? request: ${request.uri}');
      return;
    }
    try {
      _contentLength(response?.headers?.value(HttpHeaders.contentLengthHeader),
          (length) => httpMetric.responsePayloadSize = length);
      _contentLength(
          request.headers[HttpHeaders.contentLengthHeader], (length) => httpMetric.requestPayloadSize = length);
      httpMetric
        ..responseContentType = response?.headers?.value(HttpHeaders.contentTypeHeader)
        ..httpResponseCode = response?.statusCode ?? -1;
    } finally {
      unawaited(httpMetric.stop());
    }
  }

  @override
  FutureOr onError(DioError err) {
    _stopHttpMetric(err.request, err.response);
    return err;
  }

  @override
  FutureOr onRequest(RequestOptions options) async {
    final method = _HTTP_METHOD_MAPPING[options.method.toUpperCase()];
    if (method == null) {
      _logger.severe('Unknown http method: ${options.method}', null, StackTrace.current);
      return options;
    }
    final httpMetric = firebasePerformance.newHttpMetric(options.uri.toString(), method);
    await httpMetric.start();
    options.extra[_EXTRA_METRIC] = httpMetric;
    return options;
  }

  @override
  FutureOr onResponse(Response response) {
    _stopHttpMetric(response.request, response);
    return response;
  }
}
