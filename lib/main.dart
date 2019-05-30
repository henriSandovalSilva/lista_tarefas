import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(
    MaterialApp(
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //controller do campo de adicionar uma nova tarefa
  final _todoController = TextEditingController();

  List _todoList = [];

  //lê a lista de tarefas salvas no dispositivo
  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  //ação de atualizar
  Future<Null> _refresh() async {
    //coloca um delay para simular que está carregando
    await Future.delayed(
      Duration(seconds: 1),
    );

    //coloca os itens concluído para o final
    setState(() {
      _todoList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });

      //salva os itens ordenados no dispositivo
      _saveData();
    });

    return null;
  }

  //adiciona uma nova tarefa
  void _addTodo() {
    setState(() {
      FocusScope.of(context).requestFocus(FocusNode());
      //valida se o texto não é vazio
      if (_todoController.text.isNotEmpty) {
        Map<String, dynamic> newTodo = Map();
        newTodo['title'] = _todoController.text;
        newTodo['ok'] = false;
        _todoList.add(newTodo);
        //limpa o TextField
        _todoController.text = '';
        //salva o item no dispositivo
        _saveData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (String text) {
                      _addTodo();
                    },
                    decoration: InputDecoration(
                        labelText: 'Nova tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('ADD'),
                  textColor: Colors.white,
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: buildItem,
              ),
              onRefresh: _refresh,
            ),
          ),
        ],
      ),
    );
  }

  //função que cria os itens da lista
  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      onDismissed: (direction) {
        //salva o item removido para pode desfazer depois
        Map<String, dynamic> _lastRemoved;
        int _lastRemovedPosition;

        //remove o item da lista e salva
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPosition = index;
          _todoList.removeAt(index);
          _saveData();
        });

        //SnackBar com opção de desfazer a exclusão do item
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text("Item removido"),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPosition, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]['title']),
        value: _todoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(
            _todoList[index]['ok'] ? Icons.check : Icons.error,
          ),
        ),
        onChanged: (check) {
          setState(() {
            _todoList[index]['ok'] = check;
            _saveData();
          });
        },
      ),
    );
  }

  //busca o arquivo salvo no dispositivo
  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/data_tarefas.json");
  }

  //salva as tarefas salvas no dispositivo
  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  //busca as tarefas salvas no dispositivo
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
