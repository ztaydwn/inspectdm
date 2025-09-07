import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  Map<String, List<String>> _groups = {};
  bool _isLoading = true;
  bool _hasChanges = false;

  final TextEditingController _folderController = TextEditingController();
  final Map<String, TextEditingController> _groupControllers = {};
  final Map<String, List<TextEditingController>> _itemControllers = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    final configProvider = Provider.of<ConfigProvider>(context, listen: false);
    await configProvider.loadConfig();

    setState(() {
      _groups = Map.from(configProvider.groups);
      _folderController.text = configProvider.appFolder;
      _initializeControllers();
      _isLoading = false;
    });
  }

  void _initializeControllers() {
    _groupControllers.clear();
    _itemControllers.clear();

    for (final entry in _groups.entries) {
      _groupControllers[entry.key] = TextEditingController(text: entry.key);
      _itemControllers[entry.key] =
          entry.value.map((item) => TextEditingController(text: item)).toList();
    }
  }

  void _addGroup() {
    final newGroupKey = 'NUEVO GRUPO ${_groups.length + 1}';
    setState(() {
      _groups[newGroupKey] = ['Nuevo elemento'];
      _groupControllers[newGroupKey] = TextEditingController(text: newGroupKey);
      _itemControllers[newGroupKey] = [
        TextEditingController(text: 'Nuevo elemento')
      ];
      _hasChanges = true;
    });
  }

  void _addItem(String groupKey) {
    setState(() {
      _groups[groupKey]!.add('Nuevo elemento');
      _itemControllers[groupKey]!
          .add(TextEditingController(text: 'Nuevo elemento'));
      _hasChanges = true;
    });
  }

  void _removeGroup(String groupKey) {
    setState(() {
      _groups.remove(groupKey);
      _groupControllers[groupKey]?.dispose();
      _itemControllers[groupKey]?.forEach((controller) => controller.dispose());
      _groupControllers.remove(groupKey);
      _itemControllers.remove(groupKey);
      _hasChanges = true;
    });
  }

  void _removeItem(String groupKey, int index) {
    setState(() {
      _groups[groupKey]!.removeAt(index);
      _itemControllers[groupKey]![index].dispose();
      _itemControllers[groupKey]!.removeAt(index);
      _hasChanges = true;
    });
  }

  void _updateGroupName(String oldKey, String newKey) {
    if (oldKey != newKey && newKey.isNotEmpty) {
      setState(() {
        final items = _groups.remove(oldKey)!;
        _groups[newKey] = items;

        final itemControllers = _itemControllers.remove(oldKey)!;
        _itemControllers[newKey] = itemControllers;

        _groupControllers.remove(oldKey);
        _groupControllers[newKey] = TextEditingController(text: newKey);
        _hasChanges = true;
      });
    }
  }

  void _updateItem(String groupKey, int index, String newValue) {
    setState(() {
      _groups[groupKey]![index] = newValue;
      _hasChanges = true;
    });
  }

  Future<void> _saveConfig() async {
    try {
      // Actualizar nombres de grupos
      final updatedGroups = <String, List<String>>{};
      for (final entry in _groups.entries) {
        final controller = _groupControllers[entry.key];
        final groupName = controller?.text ?? entry.key;
        updatedGroups[groupName] = entry.value;
      }

      // Actualizar elementos
      for (final entry in updatedGroups.entries) {
        final controllers = _itemControllers[entry.key];
        if (controllers != null) {
          updatedGroups[entry.key] = controllers
              .map((controller) => controller.text)
              .where((text) => text.isNotEmpty)
              .toList();
        }
      }

      final configProvider =
          Provider.of<ConfigProvider>(context, listen: false);
      final success = await configProvider.saveConfig(
        groups: updatedGroups,
        appFolder: _folderController.text,
      );

      if (success) {
        setState(() {
          _groups = updatedGroups;
          _hasChanges = false;
        });
        _showSuccess('Configuración guardada exitosamente');
      } else {
        _showError('Error guardando configuración');
      }
    } catch (e) {
      _showError('Error guardando configuración: $e');
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await _showConfirmDialog(
        'Restaurar configuración por defecto',
        '¿Estás seguro de que quieres restaurar la configuración por defecto? Se perderán todos los cambios personalizados.');
    if (mounted) {
      if (confirmed) {
        try {
          final configProvider =
              Provider.of<ConfigProvider>(context, listen: false);
          final success = await configProvider.resetToDefault();
          if (success) {
            await _loadConfig();
            _showSuccess('Configuración restaurada por defecto');
          } else {
            _showError('Error restaurando configuración');
          }
        } catch (e) {
          _showError('Error restaurando configuración: $e');
        }
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
  void dispose() {
    _folderController.dispose();
    for (final controller in _groupControllers.values) {
      controller.dispose();
    }
    for (final controllers in _itemControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Personalizada'),
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              tooltip: 'Guardar cambios',
            ),
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
            ],
            onSelected: (value) {
              if (value == 'reset') {
                _resetToDefault();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Configuración de carpeta
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombre de Carpeta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _folderController,
                          decoration: const InputDecoration(
                            hintText:
                                'Nombre de la carpeta donde se guardarán las fotos',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() => _hasChanges = true);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de grupos
                Expanded(
                  child: ListView.builder(
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final groupKey = _groups.keys.elementAt(index);
                      final items = _groups[groupKey]!;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ExpansionTile(
                          title: TextField(
                            controller: _groupControllers[groupKey],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nombre del grupo',
                            ),
                            onChanged: (value) {
                              _updateGroupName(groupKey, value);
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _addItem(groupKey),
                                icon: const Icon(Icons.add),
                                tooltip: 'Agregar elemento',
                              ),
                              IconButton(
                                onPressed: () => _removeGroup(groupKey),
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Eliminar grupo',
                              ),
                            ],
                          ),
                          children: items.asMap().entries.map((entry) {
                            final itemIndex = entry.key;

                            return ListTile(
                              title: TextField(
                                controller:
                                    _itemControllers[groupKey]![itemIndex],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Descripción del elemento',
                                ),
                                onChanged: (value) {
                                  _updateItem(groupKey, itemIndex, value);
                                },
                              ),
                              trailing: IconButton(
                                onPressed: () =>
                                    _removeItem(groupKey, itemIndex),
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.red),
                                tooltip: 'Eliminar elemento',
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGroup,
        tooltip: 'Agregar grupo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
