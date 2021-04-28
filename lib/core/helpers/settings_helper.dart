import 'package:injectable/injectable.dart';

/// Helper class that handles the app's settings.
@injectable
class SettingsHelper {
  // TODO let users toggle this
  bool navigateToTourEnabled = false;
  // TODO let users toggle this
  bool enhanceToursEnabled = false;
  // TODO use system / config language
  String language = 'en-us';
}
