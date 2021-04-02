import 'package:injectable/injectable.dart';

@injectable
class SettingsHelper {
  bool navigateToTourEnabled = false;
  bool enhanceToursEnabled = false;
  // TODO use system / config language
  String language = 'en-us';
}
