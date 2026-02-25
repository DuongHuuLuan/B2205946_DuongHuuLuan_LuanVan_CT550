import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate_reponsitory.dart';
import 'package:flutter/material.dart';

class EvaluateViewmodel extends ChangeNotifier {
  final EvaluateRepository _repository;
  EvaluateViewmodel(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final List<EvaluateItem> _evaluates = [];
  List<EvaluateItem> get evaluates => List.unmodifiable(_evaluates);

  final Set<int> _creatingOrderIds = {};
  Set<int> get creatingOrderIds => Set.unmodifiable(_creatingOrderIds);

  final Map<int, int> _evaluateIdByOrder = {};
  final Set<int> _checkedOrderIds = {};

  int _page = 1;
  int _perPage = 8;
  int _total = 0;
  int _totalPages = 0;

  int get page => _page;
  int get total => _total;
  int get totalPages => _totalPages;
  bool get hasNextPage => _page < _totalPages;
  Set<int> get reviewedOrderIds => Set.unmodifiable(_evaluateIdByOrder.keys.toSet());

  bool hasEvaluateForOrder(int orderId) => _evaluateIdByOrder.containsKey(orderId);
  int? evaluateIdForOrder(int orderId) => _evaluateIdByOrder[orderId];

  Future<void> load({int perPage = 8}) async {
    if (_isLoading || _evaluates.isNotEmpty) return;
    _perPage = perPage;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _isLoading = _evaluates.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getMyEvaluates(
        page: 1,
        perPage: _perPage,
      );
      _evaluates
        ..clear()
        ..addAll(result.items);
      _page = result.page;
      _perPage = result.perPage;
      _total = result.total;
      _totalPages = result.totalPages;
      _rebuildEvaluateIndex();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasNextPage) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final result = await _repository.getMyEvaluates(
        page: nextPage,
        perPage: _perPage,
      );
      _evaluates.addAll(result.items);
      _page = result.page;
      _perPage = result.perPage;
      _total = result.total;
      _totalPages = result.totalPages;
      _rebuildEvaluateIndex();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> syncEvaluateStatusForOrders(List<int> orderIds) async {
    final uniqueIds = orderIds.where((e) => e > 0).toSet().toList()..sort();
    final pending = uniqueIds.where((id) => !_checkedOrderIds.contains(id)).toList();
    if (pending.isEmpty) return;

    var changed = false;
    for (final orderId in pending) {
      try {
        final found = await _repository.getEvaluateByOrder(orderId);
        if (found != null) {
          _evaluateIdByOrder[orderId] = found.id;
          changed = true;
        }
      } catch (_) {
        // Bỏ qua lỗi từng order để không chặn toàn bộ màn hình profile
      } finally {
        _checkedOrderIds.add(orderId);
      }
    }

    if (changed) notifyListeners();
  }

  Future<EvaluateItem> getEvaluateDetail(int evaluateId) async {
    _errorMessage = null;
    try {
      return await _repository.getEvaluateDetail(evaluateId);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<EvaluateItem> createEvaluate({
    required int orderId,
    required int rate,
    String? content,
    List<String> imagePaths = const [],
  }) async {
    if (_creatingOrderIds.contains(orderId)) {
      throw StateError("Đang gửi đánh giá cho đơn này");
    }

    _creatingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await _repository.createEvaluate(
        orderId: orderId,
        rate: rate,
        content: content,
        imagePaths: imagePaths,
      );

      _evaluateIdByOrder[created.orderId] = created.id;
      _checkedOrderIds.add(created.orderId);
      _evaluates.removeWhere((e) => e.id == created.id || e.orderId == created.orderId);
      _evaluates.insert(0, created);
      _total += 1;
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _creatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  void _rebuildEvaluateIndex() {
    for (final e in _evaluates) {
      _evaluateIdByOrder[e.orderId] = e.id;
      _checkedOrderIds.add(e.orderId);
    }
  }
}
