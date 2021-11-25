import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabs = [
      "Payments",
      "Result",
    ];
    return MaterialApp(
      title: 'BillSplitter',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: TabBar(
              isScrollable: false,
              tabs: [
                for (final tab in tabs) Tab(text: tab),
              ],
            ),
            backgroundColor: Colors.green[400],
          ),
          body: TabBarView(
            children: [
              PaymentList(),
              ResultList(),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentList extends StatefulWidget {
  @override
  _PaymentListState createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList> {
  String _newName = "Name";
  int _newPay = 0;
  String _newMemo = "";

  late _PaymentDataSource _dataSource;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _dataSource = _PaymentDataSource(context);
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              children: [
                SimpleDialogOption(
                  onPressed: () {
                    debugPrint("Delete");
                    _dataSource.deleteSelected();
                    Navigator.pop(context);
                  },
                  child: const Text("Delete Selected"),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
      child: Scrollbar(
        child: ListView(
          restorationId: 'list_view',
          children: [
            PaginatedDataTable(
              header: const Text(" "),
              dataRowHeight: 30,
              rowsPerPage: 8,
              columns: const [
                DataColumn(
                  label: Text("Name"),
                ),
                DataColumn(
                  label: Text("Payment"),
                ),
                DataColumn(
                  label: Text("Memo"),
                ),
              ],
              source: _dataSource,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Container(
                    child: TextFormField(
                      enabled: true,
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      onChanged: (String input) {
                        _newName = input;
                      },
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black45),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    child: TextFormField(
                      enabled: true,
                      controller: _paymentController,
                      decoration: const InputDecoration(
                        labelText: 'Payment',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (String input) {
                        try {
                          _newPay = int.parse(input);
                        } catch (e) {
                          _newPay = 0;
                        }
                      },
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black45),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    child: TextFormField(
                      enabled: true,
                      controller: _memoController,
                      decoration: const InputDecoration(
                        labelText: 'Memo',
                      ),
                      onChanged: (String input) {
                        _newMemo = input;
                      },
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black45),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    child: const Text("Add"),
                    onPressed: () {
                      _dataSource.add(_Payment(_newName, _newPay, _newMemo));
                      _newName = "";
                      _newMemo = "";
                      _newPay = 0;
                      _nameController.clear();
                      _paymentController.clear();
                      _memoController.clear();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () => SystemNavigator.pop(),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    Share.share(_dataSource.toString());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Payment {
  _Payment(this.name, this.money, this.description);
  final String name;
  final int money;
  final String description;

  bool selected = false;
}

class _PaymentDataSource extends DataTableSource {
  _PaymentDataSource(this.context) {
    _payments = <_Payment>[];
    Future<List<_Payment>> future = _payIO.readPayments();
    future.then((payments) {
      for (final _Payment payment in payments) {
        _payments.add(payment);
      }
      notifyListeners();
    });
  }

  @override
  DataRow getRow(int index) {
    if (index >= _payments.length) {
      index = _payments.length - 1;
      // return null;
    }
    final payment = _payments[index];
    return DataRow.byIndex(
      index: index,
      selected: payment.selected,
      onSelectChanged: (value) {
        if (value != null) {
          if (payment.selected != value) {
            _selectedCount += value ? 1 : -1;
            payment.selected = value;
            notifyListeners();
          }
        }
      },
      cells: [
        DataCell(Text(payment.name)),
        DataCell(Text('${payment.money}')),
        DataCell(Text(payment.description)),
      ],
    );
  }

  @override
  int get rowCount => _payments.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;

  void add(_Payment payment) {
    _payments.add(payment);
    _payIO.appendPayment(payment);
    notifyListeners();
  }

  void deleteSelected() {
    for (int i = _payments.length - 1; i >= 0; --i) {
      if (_payments[i].selected) {
        _payments.removeAt(i);
        --_selectedCount;
      }
    }
    _payIO.clearPayments();
    _payIO.writePayments(_payments);
    notifyListeners();
  }

  void deleteAll() {
    _selectedCount = 0;
    _payments.clear();
    _payIO.clearPayments();
    notifyListeners();
  }

  @override
  String toString() {
    String buffer = "";
    for (var p in _payments) {
      buffer +=
          p.name + "," + p.money.toString() + "," + p.description + "\r\n";
    }
    return buffer;
  }

  final BuildContext context;
  final _PaymentIO _payIO = _PaymentIO();
  late List<_Payment> _payments;
  int _selectedCount = 0;
}

class _PaymentIO {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/tatekae.csv');
  }

  void clearPayments() async {
    final file = await _localFile;
    await file.writeAsString("");
    debugPrint("cleared");
  }

  void appendPayment(_Payment payment) async {
    final file = await _localFile;
    final String line = payment.name +
        "," +
        payment.money.toString() +
        "," +
        payment.description +
        "\n";
    await file.writeAsString(line, mode: FileMode.append);
    debugPrint("appended");
  }

  void writePayments(List<_Payment> payments) async {
    final file = await _localFile;
    String lines = "";
    for (final _Payment p in payments) {
      lines += p.name + "," + p.money.toString() + "," + p.description + "\n";
    }
    await file.writeAsString(lines, mode: FileMode.write);
    debugPrint("wrote all");
  }

  Future<List<_Payment>> readPayments() async {
    List<_Payment> payments = [];
    try {
      final file = await _localFile;
      final exists = await file.exists();
      if (!exists) {
        clearPayments(); // create new file
      }
      String contents = await file.readAsString();
      debugPrint(contents);
      List<String> lines = contents.split('\n');
      for (final String line in lines) {
        List<String> items = line.split(",");
        if (items.length != 3) {
          continue;
        }
        payments.add(_Payment(items[0], int.parse(items[1]), items[2]));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return payments;
  }
}

class ResultList extends StatefulWidget {
  @override
  _ResultListState createState() => _ResultListState();
}

class _ResultListState extends State<ResultList> {
  late _SettlementDataSource _dataSource;

  @override
  Widget build(BuildContext context) {
    _dataSource = _SettlementDataSource(context);
    _dataSource.calcSettlements();
    return Scrollbar(
      child: ListView(
        restorationId: 'result_view',
        children: [
          PaginatedDataTable(
            header: const Text(" "),
            dataRowHeight: 30,
            rowsPerPage: 10,
            columns: const [
              DataColumn(label: Text("From")),
              DataColumn(label: Text("To")),
              DataColumn(label: Text("Payment")),
            ],
            source: _dataSource,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () => SystemNavigator.pop(),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  Share.share(_dataSource.toString());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Settlement {
  _Settlement(this.fromName, this.toName, this.money);
  final String fromName;
  final String toName;
  final double money;

  bool selected = false;
}

class _SettlementDataSource extends DataTableSource {
  _SettlementDataSource(this.context) {
    _settlements = <_Settlement>[];
    Future<List<_Settlement>> future = _readSettlements();
    future.then((settlements) {
      for (final _Settlement s in settlements) {
        _settlements.add(s);
      }
      notifyListeners();
    });
  }

  @override
  DataRow getRow(int index) {
    if (index >= _settlements.length) {
      index = _settlements.length - 1;
      // return null;
    }
    final settlement = _settlements[index];
    return DataRow.byIndex(
      index: index,
      selected: settlement.selected,
      onSelectChanged: (value) {
        if (value != null) {
          if (settlement.selected != value) {
            _selectedCount += value ? 1 : -1;
            settlement.selected = value;
            notifyListeners();
          }
        }
      },
      cells: [
        DataCell(Text(settlement.fromName)),
        DataCell(Text(settlement.toName)),
        DataCell(Text('${settlement.money}')),
      ],
    );
  }

  @override
  int get rowCount => _settlements.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;

  void calcSettlements() {
    debugPrint("start calc");
    Future<List<_Payment>> future = _payIO.readPayments();
    future.then((payments) {
      // calc individual sum
      var individualSums = <String, int>{};
      for (_Payment p in payments) {
        if (individualSums.containsKey(p.name)) {
          final int current = individualSums[p.name]!;
          individualSums[p.name] = current + p.money;
        } else {
          individualSums[p.name] = p.money;
        }
      }
      if (individualSums.isEmpty) {
        debugPrint("No data");
        return;
      }
      // calc total
      int amountTotal = 0;
      for (String name in individualSums.keys) {
        amountTotal += individualSums[name] as int;
      }
      final double amountPerIndividual = amountTotal / individualSums.length;
      // calc each difference from total per indvidual
      Map<String, double> differences = <String, double>{};
      for (String name in individualSums.keys) {
        final int tmp = individualSums[name]!;
        differences[name] = amountPerIndividual - tmp;
      }
      // decide settlements
      List<_Settlement> settlements = _decideSettlement(differences);
      debugPrint("finish calc");
      debugPrint("settlements num ${settlements.length}");
      _settlements.clear();
      for (_Settlement s in settlements) {
        _settlements.add(s);
      }
      notifyListeners();
    });
  }

  List<_Settlement> _decideSettlement(Map<String, double> differences) {
    Map<String, double> tmpDiffs = <String, double>{};
    for (String key in differences.keys) {
      tmpDiffs[key] = differences[key] as double;
    }
    List<_Settlement> settlements = [];
    while (true) {
      // check stop condition
      var srcCandidates = <String, double>{};
      var dstCandidates = <String, double>{};
      for (String key in tmpDiffs.keys) {
        final value = tmpDiffs[key];
        if (value != null) {
          if (value > 1e-6) {
            srcCandidates[key] = value;
          } else if (value < -1e-6) {
            dstCandidates[key] = value;
          }
        }
      }
      if (srcCandidates.isEmpty) {
        break;
      }
      // search matching pair
      String srcName = "", dstName = "";
      for (var src in srcCandidates.keys) {
        for (var dst in dstCandidates.keys) {
          if ((srcCandidates[src]! + dstCandidates[dst]!).abs() < 1e-6) {
            srcName = src;
            dstName = dst;
            break;
          }
        }
      }
      // if no pair, anything is OK
      if (srcName == "") {
        srcName = srcCandidates.keys.elementAt(0);
        dstName = dstCandidates.keys.elementAt(0);
      }
      final double srcValue = srcCandidates[srcName]!;
      final double dstValue = dstCandidates[dstName]!;
      // calc pay amount
      double payAmount = 0.0;
      if (srcValue + dstValue >= 0.0) {
        payAmount = dstValue.abs();
      } else {
        payAmount = srcValue.abs();
      }
      // pay money
      tmpDiffs[dstName] = (tmpDiffs[dstName] as double) + payAmount;
      tmpDiffs[srcName] = (tmpDiffs[srcName] as double) - payAmount;
      settlements.add(_Settlement(srcName, dstName, payAmount));
    }
    return settlements;
  }

  void deleteAll() {
    _settlements.clear();
    _clearPayments();
    notifyListeners();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/tatekae_result.csv');
  }

  void _clearPayments() async {
    final file = await _localFile;
    await file.writeAsString("");
    debugPrint("cleared");
  }

  Future<List<_Settlement>> _readSettlements() async {
    List<_Settlement> settlements = [];
    try {
      final file = await _localFile;
      bool exists = await file.exists();
      if (!exists) {
        _clearPayments(); // create new file
      }
      String contents;
      contents = await file.readAsString();
      debugPrint(contents);
      List<String> lines = contents.split('\n');
      for (final String line in lines) {
        List<String> items = line.split(",");
        if (items.length != 3) {
          continue;
        }
        settlements
            .add(_Settlement(items[0], items[1], double.parse(items[2])));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return settlements;
  }

  @override
  String toString() {
    String buffer = "";
    for (var s in _settlements) {
      buffer +=
          s.fromName + " -> " + s.toName + " : " + s.money.toString() + "\r\n";
    }
    return buffer;
  }

  final BuildContext context;
  late List<_Settlement> _settlements;
  final _PaymentIO _payIO = _PaymentIO();
  int _selectedCount = 0;
}
