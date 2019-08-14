import 'package:anlage_app_game/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ErrorWidgetWithRetry extends StatelessWidget {
  const ErrorWidgetWithRetry({
    Key key,
    @required this.error,
    @required this.onRetry,
  }) : super(key: key);

  final dynamic error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final apiError = error is ApiNetworkError ? error as ApiNetworkError : null;
    final apiErrorMessage = apiError?.cause?.message;
    final errorDescription = apiErrorMessage != null ? 'Network response: $apiErrorMessage' : '';
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Error while requesting data.',
            ),
            const SizedBox(height: 4),
            Text(
              errorDescription,
              style: Theme.of(context).textTheme.caption,
            ),
            const SizedBox(height: 4),
            RaisedButton(
              child: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
