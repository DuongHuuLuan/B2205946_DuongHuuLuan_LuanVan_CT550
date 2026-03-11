import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_designer_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/sticker_template.dart';
import 'package:flutter/material.dart';

class HelmetDesignerViewModel extends ChangeNotifier {
  final HelmetDesignerRepository _repository;

  HelmetDesignerViewModel(this._repository);

  final List<StickerTemplate> _stickerCatalog = [];
  final List<StickerLayer> _stickerLayers = [];

  HelmetDesign _currentDesign = HelmetDesign(
    id: 0,
    helmetProductId: 0,
    helmetName: "",
    helmetBaseImageUrl: "",
    stickers: const [],
    isShared: false,
  );

  bool isLoadingCatalog = false;
  bool isLoadingDesign = false;
  bool isGeneratingSticker = false;
  bool isSavingDesign = false;
  bool isSharingDesign = false;
  bool isOrderingDesign = false;
  String? errorMessage;
  String? shareUrl;
  int? selectedLayerId;
  int _nextLayerId = 1;

  List<StickerTemplate> get stickerCatalog => List.unmodifiable(_stickerCatalog);
  List<StickerLayer> get stickerLayers => List.unmodifiable(_sortedLayers());
  HelmetDesign get currentDesign => _currentDesign;
  StickerLayer? get selectedLayer => _findLayerById(selectedLayerId);
  bool get hasLayers => _stickerLayers.isNotEmpty;

  Future<void> loadStickerCatalog() async {
    if (isLoadingCatalog) return;
    isLoadingCatalog = true;
    errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.getStickerCatalog();
      _stickerCatalog
        ..clear()
        ..addAll(items);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoadingCatalog = false;
      notifyListeners();
    }
  }

  void startNewDesign({
    required int helmetProductId,
    required String helmetName,
    required String helmetBaseImageUrl,
  }) {
    _currentDesign = HelmetDesign(
      id: 0,
      helmetProductId: helmetProductId,
      helmetName: helmetName,
      helmetBaseImageUrl: helmetBaseImageUrl,
      stickers: const [],
      isShared: false,
    );
    _stickerLayers.clear();
    selectedLayerId = null;
    shareUrl = null;
    errorMessage = null;
    _nextLayerId = 1;
    notifyListeners();
  }

  void updateHelmetInfo({
    int? helmetProductId,
    String? helmetName,
    String? helmetBaseImageUrl,
  }) {
    _currentDesign = _currentDesign.copyWith(
      helmetProductId: helmetProductId,
      helmetName: helmetName,
      helmetBaseImageUrl: helmetBaseImageUrl,
      stickers: _sortedLayers(),
    );
    notifyListeners();
  }

  Future<void> loadDesign(int designId) async {
    if (isLoadingDesign) return;
    isLoadingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      final design = await _repository.getDesignDetail(designId);
      _currentDesign = design;
      _stickerLayers
        ..clear()
        ..addAll(design.stickers);
      _normalizeLayerOrder(notify: false);
      selectedLayerId = _stickerLayers.isNotEmpty ? _sortedLayers().last.id : null;
      shareUrl = null;
      _reseedNextLayerId();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoadingDesign = false;
      notifyListeners();
    }
  }

  Future<StickerTemplate?> generateAiSticker(
    AiStickerRequest request, {
    bool addToCanvas = true,
  }) async {
    if (isGeneratingSticker) return null;
    isGeneratingSticker = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sticker = await _repository.generateAiSticker(request);
      _upsertStickerTemplate(sticker);
      if (addToCanvas) {
        addStickerFromTemplate(sticker);
      } else {
        notifyListeners();
      }
      return sticker;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      isGeneratingSticker = false;
      notifyListeners();
    }
  }

  void addStickerFromTemplate(
    StickerTemplate template, {
    double x = 0.5,
    double y = 0.5,
    double scale = 0.32,
    double rotation = 0,
  }) {
    final layer = StickerLayer(
      id: _nextLayerId++,
      stickerId: template.id,
      imageUrl: template.imageUrl,
      x: _unitValue(x),
      y: _unitValue(y),
      scale: _scaleValue(scale),
      rotation: rotation,
      zIndex: _stickerLayers.length,
      crop: StickerCrop(),
    );

    _stickerLayers.add(layer);
    _normalizeLayerOrder(notify: false);
    selectedLayerId = layer.id;
    _syncCurrentDesign();
    notifyListeners();
  }

  void selectLayer(int? layerId) {
    if (layerId == null) {
      selectedLayerId = null;
      notifyListeners();
      return;
    }
    if (_findLayerById(layerId) == null) return;
    selectedLayerId = layerId;
    notifyListeners();
  }

  void updateSelectedLayerPosition({
    required double x,
    required double y,
  }) {
    _updateSelectedLayer(x: x, y: y);
  }

  void updateSelectedLayerTransform({
    double? x,
    double? y,
    double? scale,
    double? rotation,
  }) {
    _updateSelectedLayer(x: x, y: y, scale: scale, rotation: rotation);
  }

  void rotateSelectedLayerBy(double delta) {
    final layer = selectedLayer;
    if (layer == null) return;
    _updateSelectedLayer(rotation: layer.rotation + delta);
  }

  void resizeSelectedLayerBy(double factor) {
    final layer = selectedLayer;
    if (layer == null) return;
    _updateSelectedLayer(scale: layer.scale * factor);
  }

  void updateSelectedLayerTint(int? tintColorValue) {
    _updateSelectedLayer(
      tintColorValue: tintColorValue,
      clearTintColor: tintColorValue == null,
    );
  }

  void updateSelectedLayerCrop(StickerCrop crop) {
    final normalized = StickerCrop(
      left: _unitValue(crop.left),
      top: _unitValue(crop.top),
      right: _unitValue(crop.right),
      bottom: _unitValue(crop.bottom),
    );
    _updateSelectedLayer(crop: normalized);
  }

  void bringSelectedLayerForward() {
    _moveSelectedLayerBy(1);
  }

  void sendSelectedLayerBackward() {
    _moveSelectedLayerBy(-1);
  }

  void bringSelectedLayerToFront() {
    _moveSelectedLayerTo(_sortedLayers().length - 1);
  }

  void sendSelectedLayerToBack() {
    _moveSelectedLayerTo(0);
  }

  void removeSelectedLayer() {
    final layerId = selectedLayerId;
    if (layerId == null) return;

    _stickerLayers.removeWhere((layer) => layer.id == layerId);
    _normalizeLayerOrder(notify: false);
    selectedLayerId = _stickerLayers.isNotEmpty ? _sortedLayers().last.id : null;
    _syncCurrentDesign();
    notifyListeners();
  }

  Future<HelmetDesign?> saveCurrentDesign() async {
    if (isSavingDesign) return null;
    isSavingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      final saved = await _repository.saveDesign(_buildCurrentDesign());
      _currentDesign = saved;
      _stickerLayers
        ..clear()
        ..addAll(saved.stickers);
      _normalizeLayerOrder(notify: false);
      _reseedNextLayerId();
      return saved;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isSavingDesign = false;
      notifyListeners();
    }
  }

  Future<String?> shareCurrentDesign() async {
    if (isSharingDesign) return shareUrl;
    isSharingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (_currentDesign.id <= 0) {
        final saved = await saveCurrentDesign();
        if (saved == null) return null;
      }
      final url = await _repository.createShareLink(_currentDesign.id);
      shareUrl = url;
      _currentDesign = _currentDesign.copyWith(isShared: true);
      return url;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isSharingDesign = false;
      notifyListeners();
    }
  }

  Future<bool> orderCurrentDesign() async {
    if (isOrderingDesign) return false;
    isOrderingDesign = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (_currentDesign.id <= 0) {
        final saved = await saveCurrentDesign();
        if (saved == null) return false;
      }
      await _repository.orderDesign(_currentDesign.id);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isOrderingDesign = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _updateSelectedLayer({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? tintColorValue,
    bool clearTintColor = false,
    StickerCrop? crop,
  }) {
    final layerId = selectedLayerId;
    if (layerId == null) return;

    final index = _stickerLayers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) return;

    _stickerLayers[index] = _stickerLayers[index].copyWith(
      x: x == null ? null : _unitValue(x),
      y: y == null ? null : _unitValue(y),
      scale: scale == null ? null : _scaleValue(scale),
      rotation: rotation,
      tintColorValue: tintColorValue,
      clearTintColor: clearTintColor,
      crop: crop,
    );
    _syncCurrentDesign();
    notifyListeners();
  }

  void _moveSelectedLayerBy(int delta) {
    final ordered = _sortedLayers();
    final layerId = selectedLayerId;
    if (layerId == null || ordered.isEmpty) return;

    final currentIndex = ordered.indexWhere((layer) => layer.id == layerId);
    if (currentIndex < 0) return;

    _moveSelectedLayerTo(currentIndex + delta);
  }

  void _moveSelectedLayerTo(int targetIndex) {
    final ordered = _sortedLayers();
    final layerId = selectedLayerId;
    if (layerId == null || ordered.isEmpty) return;

    final currentIndex = ordered.indexWhere((layer) => layer.id == layerId);
    if (currentIndex < 0) return;

    final layer = ordered.removeAt(currentIndex);
    final safeIndex = targetIndex.clamp(0, ordered.length).toInt();
    ordered.insert(safeIndex, layer);

    _stickerLayers
      ..clear()
      ..addAll([
        for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(zIndex: i),
      ]);
    _syncCurrentDesign();
    notifyListeners();
  }

  void _normalizeLayerOrder({bool notify = true}) {
    final ordered = _sortedLayers();
    _stickerLayers
      ..clear()
      ..addAll([
        for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(zIndex: i),
      ]);
    _syncCurrentDesign();
    if (notify) {
      notifyListeners();
    }
  }

  void _syncCurrentDesign() {
    _currentDesign = _currentDesign.copyWith(stickers: _sortedLayers());
  }

  void _reseedNextLayerId() {
    var maxId = 0;
    for (final layer in _stickerLayers) {
      if (layer.id > maxId) {
        maxId = layer.id;
      }
    }
    _nextLayerId = maxId + 1;
  }

  void _upsertStickerTemplate(StickerTemplate template) {
    final index = _stickerCatalog.indexWhere((item) => item.id == template.id);
    if (index >= 0) {
      _stickerCatalog[index] = template;
      return;
    }
    _stickerCatalog.insert(0, template);
  }

  List<StickerLayer> _sortedLayers() {
    final items = List<StickerLayer>.from(_stickerLayers);
    items.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return items;
  }

  StickerLayer? _findLayerById(int? id) {
    if (id == null) return null;
    for (final layer in _stickerLayers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  HelmetDesign _buildCurrentDesign() {
    return _currentDesign.copyWith(stickers: _sortedLayers());
  }

  double _unitValue(double value) {
    return value.clamp(0.0, 1.0).toDouble();
  }

  double _scaleValue(double value) {
    return value.clamp(0.1, 4.0).toDouble();
  }
}
