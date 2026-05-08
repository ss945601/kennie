import 'dart:convert';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class _TilesetConfig {
  const _TilesetConfig({
    required this.imageAsset,
    required this.firstGid,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    this.blockingLocalTileIds = const <int>{},
  });

  final String imageAsset;
  final int firstGid;
  final double tileWidth;
  final double tileHeight;
  final int columns;
  final Set<int> blockingLocalTileIds;
}

class PunyworldRenderer {
  static const _tilesetAsset = 'tiled/punnyworld/punyworld_tileset.png';
  static const _tilePixels = 16.0;
  static const _columns = 27;

  final Map<String, Future<Sprite>> _tileCache = <String, Future<Sprite>>{};
  final Map<String, Future<Sprite>> _spriteCache = <String, Future<Sprite>>{};

  Future<PositionComponent> buildMap({
    required String tmjAsset,
    required Vector2 position,
    required double tileSize,
    int priority = -900,
    Set<String>? includeLayers,
  }) async {
    final mapJson = jsonDecode(await rootBundle.loadString(tmjAsset)) as Map<String, dynamic>;
    final width = (mapJson['width'] as num).toInt();
    final layers = (mapJson['layers'] as List<dynamic>).cast<Map<String, dynamic>>();
    final tileset = await _resolveTileset(tmjAsset, mapJson);

    final root = PositionComponent(position: position, priority: priority);
    var layerOffset = 0;
    for (final layer in layers) {
      if (layer['type'] != 'tilelayer' || layer['visible'] != true) {
        continue;
      }
      final name = layer['name'] as String? ?? '';
      if (includeLayers != null && !includeLayers.contains(name)) {
        continue;
      }

      final data = _decodeLayerData(layer);
      for (var index = 0; index < data.length; index++) {
        final gid = data[index];
        if (gid < tileset.firstGid) {
          continue;
        }
        final x = index % width;
        final y = index ~/ width;
        final sprite = await _loadTileSprite(gid, tileset);
        await root.add(
          SpriteComponent(
            sprite: sprite,
            position: Vector2(x * tileSize, y * tileSize),
            size: Vector2.all(tileSize),
            priority: priority + layerOffset,
          ),
        );
      }
      layerOffset += 1;
    }

    return root;
  }

  Future<List<Rect>> buildCollisionRects({
    required String tmjAsset,
    required double tileSize,
    required Set<String> includeLayers,
  }) async {
    final mapJson = jsonDecode(await rootBundle.loadString(tmjAsset)) as Map<String, dynamic>;
    final width = (mapJson['width'] as num).toInt();
    final height = (mapJson['height'] as num).toInt();
    final layers = (mapJson['layers'] as List<dynamic>).cast<Map<String, dynamic>>();
    final tileset = await _resolveTileset(tmjAsset, mapJson);

    final occupied = List<bool>.filled(width * height, false);
    for (final layer in layers) {
      if (layer['type'] != 'tilelayer' || layer['visible'] != true) {
        continue;
      }
      final name = layer['name'] as String? ?? '';
      if (!includeLayers.contains(name)) {
        continue;
      }

      final data = _decodeLayerData(layer);
      for (var index = 0; index < data.length && index < occupied.length; index++) {
        final gid = data[index];
        if (gid < tileset.firstGid) {
          continue;
        }

        if (tileset.blockingLocalTileIds.isEmpty) {
          occupied[index] = true;
          continue;
        }

        final localId = gid - tileset.firstGid;
        if (tileset.blockingLocalTileIds.contains(localId)) {
          occupied[index] = true;
        }
      }
    }

    final rects = <Rect>[];
    for (var row = 0; row < height; row++) {
      var column = 0;
      while (column < width) {
        final index = row * width + column;
        if (!occupied[index]) {
          column += 1;
          continue;
        }

        final start = column;
        while (column < width && occupied[row * width + column]) {
          column += 1;
        }

        rects.add(
          Rect.fromLTWH(
            start * tileSize,
            row * tileSize,
            (column - start) * tileSize,
            tileSize,
          ),
        );
      }
    }

    return rects;
  }

  Future<SpriteComponent> buildItemSprite({
    required String assetPath,
    required Vector2 position,
    required Vector2 size,
    int priority = -850,
  }) async {
    final sprite = await _spriteCache.putIfAbsent(assetPath, () => Sprite.load(assetPath));
    return SpriteComponent(
      sprite: sprite,
      position: position,
      size: size,
      priority: priority,
    );
  }

  Future<SpriteComponent> buildTileSprite({
    required int gid,
    required Vector2 position,
    required Vector2 size,
    int priority = -850,
  }) async {
    return SpriteComponent(
      sprite: await _loadPunyworldTileSprite(gid),
      position: position,
      size: size,
      priority: priority,
    );
  }

  Future<PositionComponent> buildTileGrid({
    required List<List<int>> gids,
    required Vector2 position,
    required double tileSize,
    int priority = -900,
  }) async {
    final root = PositionComponent(position: position, priority: priority);
    for (var row = 0; row < gids.length; row++) {
      final currentRow = gids[row];
      for (var column = 0; column < currentRow.length; column++) {
        final gid = currentRow[column];
        if (gid <= 0) {
          continue;
        }
        await root.add(
          SpriteComponent(
            sprite: await _loadPunyworldTileSprite(gid),
            position: Vector2(column * tileSize, row * tileSize),
            size: Vector2.all(tileSize),
            priority: priority,
          ),
        );
      }
    }
    return root;
  }

  Future<SpriteAnimationComponent> buildItemAnimation({
    required String assetPath,
    required int amount,
    required Vector2 position,
    required Vector2 size,
    double stepTime = 0.12,
    bool loop = true,
    int priority = -840,
  }) async {
    return SpriteAnimationComponent(
      animation: await SpriteAnimation.load(
        assetPath,
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2.all(16),
          loop: loop,
        ),
      ),
      position: position,
      size: size,
      priority: priority,
    );
  }

  List<int> _decodeLayerData(Map<String, dynamic> layer) {
    final rawData = layer['data'];
    if (rawData is List<dynamic>) {
      return rawData.map((value) => (value as num).toInt()).toList();
    }

    if (rawData is String && layer['encoding'] == 'base64') {
      final bytes = base64Decode(rawData);
      final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
      final values = <int>[];
      for (var offset = 0; offset < byteData.lengthInBytes; offset += 4) {
        values.add(byteData.getUint32(offset, Endian.little));
      }
      return values;
    }

    return const <int>[];
  }

  Future<_TilesetConfig> _resolveTileset(
    String tmjAsset,
    Map<String, dynamic> mapJson,
  ) async {
    final tilesets = (mapJson['tilesets'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    if (tilesets.isEmpty) {
      return const _TilesetConfig(
        imageAsset: _tilesetAsset,
        firstGid: 1,
        tileWidth: _tilePixels,
        tileHeight: _tilePixels,
        columns: _columns,
      );
    }

    final firstTileset = tilesets.first;
    final firstGid = (firstTileset['firstgid'] as num?)?.toInt() ?? 1;
    final source = firstTileset['source'] as String?;
    if (source == null || source.isEmpty) {
      return const _TilesetConfig(
        imageAsset: _tilesetAsset,
        firstGid: 1,
        tileWidth: _tilePixels,
        tileHeight: _tilePixels,
        columns: _columns,
      );
    }

    final tsjAsset = _resolveRelativeAsset(tmjAsset, source);
    final tsjJson = jsonDecode(await rootBundle.loadString(tsjAsset)) as Map<String, dynamic>;
    final image = tsjJson['image'] as String? ?? '';
    final blockingLocalTileIds = _extractBlockingLocalTileIds(tsjJson);
    return _TilesetConfig(
      imageAsset: _normalizeSpriteAssetPath(_resolveRelativeAsset(tsjAsset, image)),
      firstGid: firstGid,
      tileWidth: (tsjJson['tilewidth'] as num?)?.toDouble() ?? _tilePixels,
      tileHeight: (tsjJson['tileheight'] as num?)?.toDouble() ?? _tilePixels,
      columns: (tsjJson['columns'] as num?)?.toInt() ?? _columns,
      blockingLocalTileIds: blockingLocalTileIds,
    );
  }

  Set<int> _extractBlockingLocalTileIds(Map<String, dynamic> tsjJson) {
    final tiles = (tsjJson['tiles'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final blockingLocalTileIds = <int>{};
    for (final tile in tiles) {
      final localId = (tile['id'] as num?)?.toInt();
      if (localId == null) {
        continue;
      }

      final tileType = tile['type'] as String? ?? tile['class'] as String? ?? '';
      final objectGroup = tile['objectgroup'] as Map<String, dynamic>?;
      final objects = (objectGroup?['objects'] as List<dynamic>? ?? const <dynamic>[]);
      if (tileType == 'water' || objects.isNotEmpty) {
        blockingLocalTileIds.add(localId);
      }
    }
    return blockingLocalTileIds;
  }

  String _normalizeSpriteAssetPath(String assetPath) {
    const imagesPrefix = 'assets/images/';
    const assetsPrefix = 'assets/';
    if (assetPath.startsWith(imagesPrefix)) {
      return assetPath.substring(imagesPrefix.length);
    }
    if (assetPath.startsWith(assetsPrefix)) {
      return assetPath.substring(assetsPrefix.length);
    }
    return assetPath;
  }

  String _resolveRelativeAsset(String baseAsset, String relativePath) {
    final lastSlash = baseAsset.lastIndexOf('/');
    final baseDirectory = lastSlash >= 0 ? baseAsset.substring(0, lastSlash + 1) : '';
    final rawParts = (baseDirectory + relativePath).split('/');
    final parts = <String>[];
    for (final part in rawParts) {
      if (part.isEmpty || part == '.') {
        continue;
      }
      if (part == '..') {
        if (parts.isNotEmpty) {
          parts.removeLast();
        }
        continue;
      }
      parts.add(part);
    }
    return parts.join('/');
  }

  Future<Sprite> _loadPunyworldTileSprite(int gid) {
    return _loadTileSprite(
      gid,
      const _TilesetConfig(
        imageAsset: _tilesetAsset,
        firstGid: 1,
        tileWidth: _tilePixels,
        tileHeight: _tilePixels,
        columns: _columns,
      ),
    );
  }

  Future<Sprite> _loadTileSprite(int gid, _TilesetConfig tileset) {
    final localId = gid - tileset.firstGid;
    final cacheKey = '${tileset.imageAsset}#$localId';
    return _tileCache.putIfAbsent(cacheKey, () {
      final srcX = (localId % tileset.columns) * tileset.tileWidth;
      final srcY = (localId ~/ tileset.columns) * tileset.tileHeight;
      return Sprite.load(
        tileset.imageAsset,
        srcPosition: Vector2(srcX, srcY),
        srcSize: Vector2(tileset.tileWidth, tileset.tileHeight),
      );
    });
  }
}