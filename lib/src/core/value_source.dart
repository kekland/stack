import 'package:flutter/foundation.dart';
import 'package:stack/stack.dart';

abstract class ValueSource<T> with Disposable {
  ValueSource({required this.logger}) {
    _dispatcher = di.dispatcherFor<T>();
    initialize();

    $streamListen(_dispatcher.eventStreamIgnoringSource(this), $onValueEvent);
  }

  final Logger logger;
  late final ValueDispatcher<T> _dispatcher;

  late final isInitialStateSignal = $signal<bool>(true);
  bool get isInitialState => isInitialStateSignal.value;

  late final isLoadingSignal = $signal<bool>(false);
  bool get isLoading => isLoadingSignal.value;

  late final errorSignal = $signal<(Object, StackTrace)?>(null);
  Object? get error => errorSignal.value?.$1;
  StackTrace? get errorStackTrace => errorSignal.value?.$2;

  bool get hasValue => hasValueSignal.value;
  Computed<bool> get hasValueSignal;

  bool _isRefreshing = false;

  @protected
  Future<void> _loadInternal({bool refresh = false});

  Future<void> load() async {
    if (isLoading || _isRefreshing) return;

    isLoadingSignal.value = true;
    isInitialStateSignal.value = false;
    errorSignal.value = null;

    try {
      _loadInternal(refresh: false);
    } catch (e, stackTrace) {
      errorSignal.value = (e, stackTrace);
    } finally {
      isLoadingSignal.value = false;
    }
  }

  Future<void> refresh() async {
    if (isLoading || _isRefreshing) return;

    _isRefreshing = true;
    isInitialStateSignal.value = false;

    try {
      _loadInternal(refresh: true);
      errorSignal.value = null;
    } catch (e, stackTrace) {
      errorSignal.value = (e, stackTrace);
      handleError(e, stackTrace);
    } finally {
      _isRefreshing = false;
    }
  }

  void reset() {
    isInitialStateSignal.value = true;
    isLoadingSignal.value = false;
    errorSignal.value = null;
  }

  void initialize() {}
  void $onValueEvent(ValueEvent<T> event) {}
}

abstract class SingleValueSource<TData, TProxy extends ValueProxy<TData>> extends ValueSource<TData> {
  SingleValueSource({required super.logger, TData? initialValue}) : super() {
    if (initialValue != null) {
      valueSignal.value = _dispatcher.createProxy(initialValue) as TProxy;
      isInitialStateSignal.value = false;
    }
  }

  late final valueSignal = $signal<TProxy?>(null);
  TProxy? get value => valueSignal.value;

  @override
  late final hasValueSignal = $computed<bool>(() => valueSignal.value != null);

  Future<TData?> performLoad();

  @override
  Future<void> _loadInternal({bool refresh = false}) async {
    final data = await performLoad();
    value?.dispose();

    if (data != null) {
      valueSignal.value = _dispatcher.createProxy(data) as TProxy;
      _dispatcher.dispatchFetch(this, data);
    } else {
      valueSignal.value = null;
    }
  }

  @override
  void reset() {
    super.reset();
    value?.dispose();
    valueSignal.value = null;
  }

  @override
  void dispose() {
    value?.dispose();
    super.dispose();
  }
}

abstract class ListValueSource<TData, TProxy extends ValueProxy<TData>> extends ValueSource<TData> {
  ListValueSource({required super.logger, List<TData>? initialValue}) : super() {
    if (initialValue != null) {
      valueSignal.value = initialValue.map((e) => _dispatcher.createProxy(e) as TProxy).toList();
      isInitialStateSignal.value = false;
    }
  }

  late final valueSignal = $signal<List<TProxy>?>(null);
  List<TProxy>? get value => valueSignal.value;

  @override
  late final hasValueSignal = $computed<bool>(() => valueSignal.value != null && valueSignal.value!.isNotEmpty);

  late final itemCountSignal = $computed<int>(() => valueSignal.value?.length ?? 0);
  int get itemCount => itemCountSignal.value;

  late final totalItemCountSignal = $signal<int?>(null);
  int? get totalItemCount => totalItemCountSignal.value;

  late final _paginationKey = $signal<Object?>(null);
  late final hasMoreSignal = $computed<bool>(() => valueSignal.value == null || _paginationKey.value != null);
  bool get hasMore => hasMoreSignal.value;

  TProxy operator [](int index) => value![index];

  Future<(List<TData> items, Object? nextPageToken, int? totalCount)> performLoad(Object? token);

  @override
  Future<void> _loadInternal({bool refresh = false}) async {
    final (data, nextPageToken, totalCount) = await performLoad(_paginationKey.value);
    final newProxies = data.map((e) => _dispatcher.createProxy(e) as TProxy).toList();
    for (final v in data) _dispatcher.dispatchFetch(this, v);

    if (refresh) {
      if (value != null) for (final v in value!) v.dispose();
      valueSignal.value = newProxies;
    } else {
      final newList = [if (value != null) ...value!, ...newProxies];
      valueSignal.value = newList;
    }

    _paginationKey.value = nextPageToken;
    totalItemCountSignal.value = totalCount;
  }

  @override
  void reset() {
    super.reset();
    if (value != null) for (final v in value!) v.dispose();
    valueSignal.value = null;
    _paginationKey.value = null;
    totalItemCountSignal.value = null;
  }

  @override
  void dispose() {
    if (value != null) for (final v in value!) v.dispose();
    super.dispose();
  }

  void $insertAt(int index, TData item) {
    final list = value;
    final proxy = _dispatcher.createProxy(item) as TProxy;

    if (list == null) {
      valueSignal.value = [proxy];
    } else {
      if (index < 0 || index > list.length) throw RangeError.index(index, list, 'index');
      valueSignal.value = [...list..insert(index, proxy)];
    }
  }

  void $removeAt(int index) {
    final list = value;
    if (list == null) throw Exception('List is null');
    if (index < 0 || index >= list.length) throw RangeError.index(index, list, 'index');

    list[index].dispose();
    valueSignal.value = [...list..removeAt(index)];
  }

  @override
  void $onValueEvent(ValueEvent<TData> event) {
    if (event is ValueDeleteEvent<TData>) {
      final id = event.id;
      final index = value?.indexWhere((e) => _dispatcher.identify(e.value) == id);
      if (index != null && index >= 0) {
        $removeAt(index);
      }
    }
  }
}

mixin QueryableValueSource<TQuery, T> on ValueSource<T> {
  late final _debouncer = $debouncer(load, delay: const Duration(milliseconds: 500));
  late final _query = $signal<TQuery?>(null);
  TQuery? get query => _query.value;
  set query(TQuery value) => _query.value = value;
  bool get isQueryEmpty => query == null || (query is String && (query as String).isEmpty);

  bool get providesResultsOnEmptyQuery => true;
  bool _isLoadingOverridden = false;

  @override
  void initialize() {
    super.initialize();

    $effect(() {
      _query.value;
      untracked(() => reset());

      if (!isQueryEmpty || providesResultsOnEmptyQuery) {
        isInitialStateSignal.value = false;
        isLoadingSignal.value = true;
        _isLoadingOverridden = true;
        _debouncer.schedule();
      }
    });
  }

  @override
  Future<void> load() async {
    if (_isLoadingOverridden) {
      isLoadingSignal.value = false;
      _isLoadingOverridden = false;
    }

    if (isQueryEmpty && !providesResultsOnEmptyQuery) return;
    return super.load(); // todo: ignore loads that finished after query changed
  }
}
