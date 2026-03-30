import 'package:flutter/widgets.dart';
import '../../../../../stack/lib/stack.dart';

/// A scope container that holds references to its descendant widgets of type [T].
///
/// Internally, it holds references to contexts of the children, so that when they are updated, we don't need to
/// rebind them.
///
/// This is used in conjunction with [Scope] and [useScopedBinding].
class ScopeContainer<T extends Widget> with ChangeNotifier, Disposable {
  ScopeContainer();

  late final _elements = <BuildContext>{};
  Set<T> get children => _elements.map((e) => e.widget as T).toSet();

  void bind(BuildContext context) {
    assert(!_elements.contains(context));
    _elements.add(context);
    notifyListeners();
  }

  void unbind(BuildContext context) {
    assert(_elements.contains(context));
    _elements.remove(context);
    notifyListeners();
  }

  @override
  void dispose() {
    _elements.clear();
    super.dispose();
  }
}

/// A scope provides the [ScopeContainer<T>] to its descendants.
///
/// Use the [useScopedBinding] hook in the descendant widgets to bind/unbind them automatically.
class Scope<T extends ScopeContainer> extends InheritedWidget {
  const Scope({
    super.key,
    required this.container,
    required super.child,
  });

  final T container;

  static Scope<T> of<T extends ScopeContainer>(BuildContext context) => maybeOf(context)!;
  static Scope<T>? maybeOf<T extends ScopeContainer>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<Scope<T>>();
  }

  void bind(BuildContext context) => container.bind(context);
  void unbind(BuildContext context) => container.unbind(context);

  @override
  bool updateShouldNotify(Scope<T> oldWidget) => oldWidget.container != container;
}

/// A hook to bind/unbind this widget to the nearest ancestor [Scope<T>].
///
/// If [require] is true, it will throw if no ancestor scope is found.
T? useScopedBinding<T extends ScopeContainer>({bool require = false, List<Object?> keys = const []}) {
  final context = useContext();
  final scope = Scope.maybeOf<T>(context);
  if (require && scope == null) {
    throw FlutterError('No Scoped<$T> ancestor found in the widget tree.');
  }

  useEffect(() {
    scope?.bind(context);
    return () => scope?.unbind(context);
  }, [scope, ...keys]);

  return scope?.container;
}

/// A hook to create a [ScopeContainer<T>] that is disposed when the widget is disposed.
///
/// This is useful to create a scope container for a [Scope] widget.
T useScopeContainer<T extends ScopeContainer>(T Function() create) {
  final container = useDisposable(create);
  return container;
}
