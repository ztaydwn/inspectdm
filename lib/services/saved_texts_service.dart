import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedTextsService {
  static const String _savedTextsKey = 'saved_description_texts';
  static const int _maxSavedTexts = 20; // Límite de textos guardados

  // Textos por defecto (los que estaban como presets)
  static const List<String> _defaultTexts = [
    'oxidado',
    'roto',
    'faltante',
    'corrosión',
    'grieta',
    'fisura',
    'humedad',
    'desgastado',
    'suelto',
    'mal estado',
    'presenta daños',
    'no funciona',
    'en buen estado',
    'requiere mantenimiento',
  ];

  /// Obtiene todos los textos guardados
  static Future<List<String>> getSavedTexts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final textsJson = prefs.getString(_savedTextsKey);

      if (textsJson != null) {
        final List<dynamic> textsList = json.decode(textsJson);
        return textsList.cast<String>();
      }
    } catch (e) {
      print('Error cargando textos guardados: $e');
    }

    // Si no hay textos guardados, usar los por defecto
    return List.from(_defaultTexts);
  }

  /// Guarda un nuevo texto (se agrega al inicio de la lista)
  static Future<bool> saveText(String text) async {
    if (text.trim().isEmpty) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTexts = await getSavedTexts();

      // Remover el texto si ya existe (para evitar duplicados)
      savedTexts.removeWhere(
          (savedText) => savedText.toLowerCase() == text.toLowerCase());

      // Agregar el nuevo texto al inicio
      savedTexts.insert(0, text.trim());

      // Limitar el número de textos guardados
      if (savedTexts.length > _maxSavedTexts) {
        savedTexts = savedTexts.take(_maxSavedTexts).toList();
      }

      final textsJson = json.encode(savedTexts);
      return await prefs.setString(_savedTextsKey, textsJson);
    } catch (e) {
      print('Error guardando texto: $e');
      return false;
    }
  }

  /// Elimina un texto específico
  static Future<bool> removeText(String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedTexts = await getSavedTexts();

      savedTexts.removeWhere((savedText) => savedText == text);

      final textsJson = json.encode(savedTexts);
      return await prefs.setString(_savedTextsKey, textsJson);
    } catch (e) {
      print('Error eliminando texto: $e');
      return false;
    }
  }

  /// Restaura los textos por defecto
  static Future<bool> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final textsJson = json.encode(_defaultTexts);
      return await prefs.setString(_savedTextsKey, textsJson);
    } catch (e) {
      print('Error restaurando textos por defecto: $e');
      return false;
    }
  }

  /// Limpia todos los textos guardados
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_savedTextsKey);
    } catch (e) {
      print('Error limpiando textos: $e');
      return false;
    }
  }

  /// Verifica si hay textos personalizados (diferentes a los por defecto)
  static Future<bool> hasCustomTexts() async {
    try {
      final savedTexts = await getSavedTexts();
      return !_listsEqual(savedTexts, _defaultTexts);
    } catch (e) {
      print('Error verificando textos personalizados: $e');
      return false;
    }
  }

  /// Compara dos listas de strings
  static bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
