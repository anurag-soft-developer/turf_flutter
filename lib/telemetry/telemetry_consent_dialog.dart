import 'package:flutter/material.dart';
import 'package:flutter_application_1/settings/settings_controller.dart';
import 'package:flutter_application_1/telemetry/util/app_log.dart';
import 'package:get/get.dart';

/// Forwards pause and resume, and asks for analytics consent once.
class TelemetryConsentDialog extends StatefulWidget {
  const TelemetryConsentDialog({super.key, required this.child});

  final Widget child;

  @override
  State<TelemetryConsentDialog> createState() => _TelemetryConsentDialogState();
}

class _TelemetryConsentDialogState extends State<TelemetryConsentDialog>
    with WidgetsBindingObserver {
  var _promptScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLog.instance.onRoute(Get.currentRoute);
      _promptIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppLog.instance.onPause();
    } else if (state == AppLifecycleState.resumed) {
      AppLog.instance.onResume();
    }
  }

  Future<void> _promptIfNeeded() async {
    await AppLog.instance.start();
    if (!mounted || _promptScheduled || !AppLog.instance.shouldPromptConsent) {
      return;
    }
    final navigator = Get.key.currentState;
    if (navigator == null || !navigator.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptIfNeeded();
      });
      return;
    }
    _promptScheduled = true;
    await navigator.push<void>(
      DialogRoute<void>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Help us improve Sport verse'),
            content: const Text(
              'Would you do us a favor? Sharing which screens you visit, how long you stay, and any errors you hit helps us make the app better. Reports are sent about once an hour, and you can turn this off anytime in Settings. The app works the same if you say no.',
            ),
            actions: [
              TextButton(
                onPressed: () => _choose(dialogContext, false),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () => _choose(dialogContext, true),
                child: const Text("Sure, I'll help"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _choose(BuildContext dialogContext, bool allowed) async {
    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().setAnalyticsConsent(allowed);
    } else {
      await AppLog.instance.setConsent(allowed);
    }
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
