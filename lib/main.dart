import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SementeVerdeApp());

class SementeVerdeApp extends StatelessWidget {
  const SementeVerdeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Semente Verde',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2F7650),
            surface: const Color(0xFFF6F8F2),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF6F8F2),
        ),
        home: const HomePage(),
      );
}

class EcoTask {
  EcoTask({required this.title, this.done = false});
  final String title;
  bool done;

  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  factory EcoTask.fromJson(Map<String, dynamic> json) =>
      EcoTask(title: json['title'] as String, done: json['done'] as bool);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _storageKey = 'eco_tasks_v1';
  final List<EcoTask> _tasks = [];
  final _input = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Quando o app abre, recuperamos o texto salvo e remontamos cada hábito da lista.
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(decoded.map((item) =>
              EcoTask.fromJson(Map<String, dynamic>.from(item as Map))));
      } catch (_) {
        // Se um dado antigo estiver incompleto, a tela continua utilizável.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  // Transformamos a lista em JSON e gravamos no armazenamento local do celular.
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<void> _addTask() async {
    final title = _input.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _tasks.insert(0, EcoTask(title: title));
      _input.clear();
    });
    await _saveTasks();
  }

  Future<void> _toggleTask(int index, bool? value) async {
    setState(() => _tasks[index].done = value ?? false);
    await _saveTasks();
  }

  Future<void> _removeTask(int index) async {
    setState(() => _tasks.removeAt(index));
    await _saveTasks();
  }

  int get _completed => _tasks.where((task) => task.done).length;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _tasks.isEmpty ? 0.0 : _completed / _tasks.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semente Verde',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Meu impacto',
            icon: const Icon(Icons.eco_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImpactPage(
                  tasks: List.unmodifiable(_tasks),
                  completed: _completed,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F0E4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pequenas atitudes, grande mudança 🌱',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        const Text('Registre um hábito sustentável para hoje.'),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('$_completed de ${_tasks.length} atitudes concluídas'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _input,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTask(),
                    decoration: InputDecoration(
                      hintText: 'Ex.: Levar minha garrafa reutilizável',
                      labelText: 'Novo hábito',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      suffixIcon: IconButton(
                        onPressed: _addTask,
                        icon: const Icon(Icons.add_circle),
                        tooltip: 'Adicionar hábito',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Minha lista',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (_tasks.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                            'Sua lista está vazia. Adicione uma atitude sustentável para começar.'),
                      ),
                    ),
                  ..._tasks.asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        value: task.done,
                        onChanged: (value) => _toggleTask(index, value),
                        title: Text(task.title,
                            style: TextStyle(
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                        secondary: IconButton(
                          tooltip: 'Remover hábito',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeTask(index),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImpactPage(
                          tasks: List.unmodifiable(_tasks),
                          completed: _completed,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('Ver meu impacto'),
                  ),
                ],
              ),
            ),
    );
  }
}

class ImpactPage extends StatelessWidget {
  const ImpactPage({super.key, required this.tasks, required this.completed});
  final List<EcoTask> tasks;
  final int completed;

  static const _tips = [
    'Leve uma sacola reutilizável quando for às compras.',
    'Apague as luzes ao sair de um cômodo.',
    'Prefira uma garrafa reutilizável para reduzir descartáveis.',
    'Separe recicláveis limpos e secos para a coleta seletiva.',
    'Planeje as refeições para evitar desperdício de alimentos.',
    'Feche a torneira enquanto escova os dentes.',
    'Quando possível, caminhe, pedale ou compartilhe carona.',
  ];

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final tip = _tips[day % _tips.length];
    final ratio = tasks.isEmpty ? 0.0 : completed / tasks.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Meu impacto')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F0E4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.eco, size: 48, color: Color(0xFF2F7650)),
                const SizedBox(height: 12),
                Text('$completed',
                    style: const TextStyle(
                        fontSize: 44, fontWeight: FontWeight.w900)),
                const Text('atitudes concluídas na sua lista'),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: ratio, minHeight: 10),
                const SizedBox(height: 8),
                Text('${(ratio * 100).round()}% de conclusão'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dica sustentável do dia',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(tip),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
              'O contador considera apenas os hábitos registrados e concluídos neste aparelho.'),
        ],
      ),
    );
  }
}
