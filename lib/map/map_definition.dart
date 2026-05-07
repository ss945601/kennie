class MapDefinition {
  const MapDefinition({
    required this.id,
    required this.tmxAsset,
    required this.defaultSpawnId,
  });

  final String id;
  final String tmxAsset;
  final String defaultSpawnId;
}

const mapDefinitions = <String, MapDefinition>{
  'town': MapDefinition(
    id: 'town',
    tmxAsset: 'maps/town.tmx',
    defaultSpawnId: 'default',
  ),
  'house': MapDefinition(
    id: 'house',
    tmxAsset: 'maps/house.tmx',
    defaultSpawnId: 'entry',
  ),
};
