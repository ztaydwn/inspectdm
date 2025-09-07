import 'package:flutter/material.dart';
import '../services/saved_texts_service.dart';

class SavedTextsScreen extends StatefulWidget {
  const SavedTextsScreen({super.key});

  @override
  State<SavedTextsScreen> createState() => _SavedTextsScreenState();
}

class _SavedTextsScreenState extends State<SavedTextsScreen> {
  List<String> _savedTexts = [];
  bool _isLoading = true;
  final TextEditingController _newTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedTexts();
  }

  @override
  void dispose() {
    _newTextController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedTexts() async {
    setState(() => _isLoading = true);
    try {
      final texts = await SavedTextsService.getSavedTexts();
      setState(() {
        _savedTexts = texts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error cargando textos: $e');
    }
  }

  Future<void> _addNewText() async {
    final text = _newTextController.text.trim();
    if (text.isEmpty) return;

    try {
      final success = await SavedTextsService.saveText(text);
      if (success) {
        _newTextController.clear();
        await _loadSavedTexts();
        _showSuccess('Texto agregado exitosamente');
      } else {
        _showError('Error agregando texto');
      }
    } catch (e) {
      _showError('Error agregando texto: $e');
    }
  }

  Future<void> _removeText(String text) async {
    try {
      final success = await SavedTextsService.removeText(text);
      if (success) {
        await _loadSavedTexts();
        _showSuccess('Texto eliminado');
      } else {
        _showError('Error eliminando texto');
      }
    } catch (e) {
      _showError('Error eliminando texto: $e');
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await _showConfirmDialog(
      'Restaurar textos por defecto',
      '¿Estás seguro de que quieres restaurar los textos por defecto? Se perderán todos los textos personalizados.'
    );
    
    if (confirmed) {
      try {
        final success = await SavedTextsService.resetToDefault();
        if (success) {
          await _loadSavedTexts();
          _showSuccess('Textos restaurados por defecto');
        } else {
          _showError('Error restaurando textos');
        }
      } catch (e) {
        _showError('Error restaurando textos: $e');
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await _showConfirmDialog(
      'Limpiar todos los textos',
      '¿Estás seguro de que quieres eliminar todos los textos guardados?'
    );
    
    if (confirmed) {
      try {
        final success = await SavedTextsService.clearAll();
        if (success) {
          await _loadSavedTexts();
          _showSuccess('Todos los textos eliminados');
        } else {
          _showError('Error eliminando textos');
        }
      } catch (e) {
        _showError('Error eliminando textos: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Textos Guardados'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Restaurar por defecto'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpiar todos'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'reset') {
                _resetToDefault();
              } else if (value == 'clear') {
                _clearAll();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Agregar nuevo texto
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agregar Nuevo Texto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newTextController,
                                decoration: const InputDecoration(
                                  hintText: 'Escribe un texto para guardar',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _addNewText(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _addNewText,
                              child: const Text('Agregar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Lista de textos guardados
                Expanded(
                  child: _savedTexts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.text_fields, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay textos guardados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Los textos que escribas se guardarán automáticamente',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _savedTexts.length,
                          itemBuilder: (context, index) {
                            final text = _savedTexts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(text),
                                trailing: IconButton(
                                  onPressed: () => _removeText(text),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Eliminar texto',
                                ),
                                onTap: () {
                                  // Copiar al portapapeles
                                  // Clipboard.setData(ClipboardData(text: text));
                                  _showSuccess('Texto: "$text"');
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
