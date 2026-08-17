import '../local/json_file_store.dart';
import 'app_repository.dart';

class LocalAppRepository implements AppRepository {
  LocalAppRepository({JsonFileStore? store})
    : _store = store ?? JsonFileStore();

  final JsonFileStore _store;

  @override
  Future<AppStateData?> load() async {
    final json = await _store.read();
    return json == null ? null : AppStateData.fromJson(json);
  }

  @override
  Future<void> save(AppStateData state) => _store.write(state.toJson());
}

class InMemoryAppRepository implements AppRepository {
  InMemoryAppRepository([this.state]);

  AppStateData? state;

  @override
  Future<AppStateData?> load() async => state;

  @override
  Future<void> save(AppStateData state) async {
    this.state = state;
  }
}
