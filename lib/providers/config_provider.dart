import 'package:flutter/foundation.dart';
import '../services/config_service.dart';

class ConfigProvider extends ChangeNotifier {
  Map<String, List<String>> _groups = {};
  String _appFolder = '';
  bool _isLoading = true;
  bool _hasCustomConfig = false;

  Map<String, List<String>> get groups => _groups;
  String get appFolder => _appFolder;
  bool get isLoading => _isLoading;
  bool get hasCustomConfig => _hasCustomConfig;

  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await ConfigService.getCustomGroups();
      _appFolder = await ConfigService.getCustomAppFolder();
      _hasCustomConfig = await ConfigService.hasCustomConfig();
    } catch (e) {
      debugPrint('Error loading config: $e');
      // Fallback to default values
      _groups = ConfigService.defaultGroups;
      _appFolder = ConfigService.defaultAppFolder;
      _hasCustomConfig = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveConfig({
    required Map<String, List<String>> groups,
    required String appFolder,
  }) async {
    try {
      final groupsSuccess = await ConfigService.saveCustomGroups(groups);
      final folderSuccess = await ConfigService.saveCustomAppFolder(appFolder);
      
      if (groupsSuccess && folderSuccess) {
        _groups = groups;
        _appFolder = appFolder;
        _hasCustomConfig = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving config: $e');
      return false;
    }
  }

  Future<bool> resetToDefault() async {
    try {
      final success = await ConfigService.resetToDefault();
      if (success) {
        await loadConfig();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error resetting config: $e');
      return false;
    }
  }

  // Helper methods for easy access
  List<String> getGroupNames() => _groups.keys.toList();
  List<String> getGroupItems(String groupName) => _groups[groupName] ?? [];
  bool hasGroup(String groupName) => _groups.containsKey(groupName);
}
