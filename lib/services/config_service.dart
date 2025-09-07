import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ConfigService {
  static const String _configKey = 'custom_description_groups';
  static const String _appFolderKey = 'custom_app_folder';
  
  // Configuración por defecto (la que está en constants.dart)
  static Map<String, List<String>> get defaultGroups => kDescriptionGroups;
  static String get defaultAppFolder => kAppFolder;
  
  // Obtener configuración personalizada
  static Future<Map<String, List<String>>> getCustomGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        final Map<String, dynamic> configMap = json.decode(configJson);
        return configMap.map((key, value) => MapEntry(key, List<String>.from(value)));
      }
    } catch (e) {
      print('Error cargando configuración personalizada: $e');
    }
    
    // Si no hay configuración personalizada, usar la por defecto
    return defaultGroups;
  }
  
  // Guardar configuración personalizada
  static Future<bool> saveCustomGroups(Map<String, List<String>> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(groups);
      return await prefs.setString(_configKey, configJson);
    } catch (e) {
      print('Error guardando configuración personalizada: $e');
      return false;
    }
  }
  
  // Obtener nombre de carpeta personalizado
  static Future<String> getCustomAppFolder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_appFolderKey) ?? defaultAppFolder;
    } catch (e) {
      print('Error cargando nombre de carpeta personalizado: $e');
      return defaultAppFolder;
    }
  }
  
  // Guardar nombre de carpeta personalizado
  static Future<bool> saveCustomAppFolder(String folderName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_appFolderKey, folderName);
    } catch (e) {
      print('Error guardando nombre de carpeta personalizado: $e');
      return false;
    }
  }
  
  // Restaurar configuración por defecto
  static Future<bool> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);
      await prefs.remove(_appFolderKey);
      return true;
    } catch (e) {
      print('Error restaurando configuración por defecto: $e');
      return false;
    }
  }
  
  // Verificar si hay configuración personalizada
  static Future<bool> hasCustomConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_configKey) || prefs.containsKey(_appFolderKey);
    } catch (e) {
      print('Error verificando configuración personalizada: $e');
      return false;
    }
  }
}
