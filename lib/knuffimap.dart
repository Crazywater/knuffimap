import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart' show lowerBound;
import 'package:knuffimap/reference.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

/// Turns a [Reference] into a [Stream] of sorted [KnuffiMap]s.
///
/// This adapter subscribes to any changes on the given [Query] and keeps a
/// sorted mapping from [String] key to value in a [KnuffiMap].
///
/// On every change, the [KnuffiMap] is updated and [stream] emits the new
/// current state.
class MapAdapter<T> {
  final _subject = BehaviorSubject<KnuffiMap<T>>();
  final Reference _ref;
  final T Function(Map) _deserializer;
  final Comparator<T> _comparator;

  List<StreamSubscription> _subscriptions;
  KnuffiMap<T> _map;

  MapAdapter(this._ref, this._deserializer,
      {@required Comparator<T> comparator})
      : _comparator = comparator;

  /// A [Stream] which emits the full state of the [Query] in a [KnuffiMap]
  /// on every change.
  ///
  /// This stream fires once on subscription with the current state, and then
  /// again on every change.
  Stream<KnuffiMap<T>> get stream => _subject.stream;

  /// Starts listening on the given query.
  ///
  /// Emits the initial state in [stream].
  Future<void> open() async {
    assert(_subscriptions == null, "Already open!");

    _map = KnuffiMap<T>(_comparator);

    _subscriptions = [
      _ref.onChildAdded.listen((event) {
        _map._add(event.snapshot.key, _deserializer(event.snapshot.value));
        _subject.add(_map);
      }),
      _ref.onChildChanged.listen((event) {
        _map._update(event.snapshot.key, _deserializer(event.snapshot.value));
        _subject.add(_map);
      }),
      _ref.onChildRemoved.listen((event) {
        _map._remove(event.snapshot.key);
        _subject.add(_map);
      }),
      // Moves are ignored on purpose, we keep our own sort order.
    ];

    await _ref.loadInitialData();
    _subject.add(_map);
  }

  /// Stops listening to updates on the [Query] and closes [stream].
  void close() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subject.close();
    _map = null;
  }
}

/// A read-only sorted map that is backed by a [Reference].
class KnuffiMap<T> {
  final _map = <String, T>{};
  final _sortedKeys = <String>[];
  final Comparator<T> _comparator;

  KnuffiMap(this._comparator);

  void _add(String key, T value) {
    _map[key] = value;
    final index = lowerBound(_sortedKeys, key, compare: _keyComparator);
    _sortedKeys.insert(index, key);
  }

  void _remove(String key) {
    final index = lowerBound(_sortedKeys, key, compare: _keyComparator);
    _sortedKeys.removeAt(index);
    _map.remove(key);
  }

  void _update(String key, T value) {
    final oldIndex = lowerBound(_sortedKeys, key, compare: _keyComparator);
    _map[key] = value;
    final newIndex = lowerBound(_sortedKeys, key, compare: _keyComparator);
    if (oldIndex == newIndex) return;
    _sortedKeys.removeAt(oldIndex);
    _sortedKeys.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, key);
  }

  T operator [](String key) => _map[key];

  Iterable<String> get keys => UnmodifiableListView(_sortedKeys);

  Iterable<T> get values => _sortedKeys.map((key) => _map[key]);

  bool get isEmpty => _map.isEmpty;

  bool get isNotEmpty => _map.isNotEmpty;

  bool containsKey(String key) => _map.containsKey(key);

  void forEach(void Function(String key, T value) callback) {
    for (var key in _sortedKeys) {
      callback(key, this[key]);
    }
  }

  int _keyComparator(String left, String right) =>
      _comparator(this[left], this[right]);
}
