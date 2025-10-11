// An example file that contains a proxy, dispatcher, and a few value sources for an imaginary [Post] class.

import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

/// A sample data class representing a social media post.
@immutable
class Post {
  const Post({required this.id, required this.body, required this.isLiked});

  final String id;
  final String body;
  final bool isLiked;

  Post copyWith({String? id, String? body, bool? isLiked}) {
    return Post(
      id: id ?? this.id,
      body: body ?? this.body,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

/// A sample API class that simulates a service for posts.
class PostApi {
  static Future<List<Post>> fetchPosts() async {
    await Future.delayed(const Duration(seconds: 1));
    return List.generate(
      10,
      (index) => Post(id: '$index', body: 'This is post number $index', isLiked: false),
    );
  }

  static Future<Post> fetchPost(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    return Post(id: id, body: 'This is a post with id $id', isLiked: false);
  }

  static Future<Post> likePost(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Post(id: id, body: 'This is a post with id $id', isLiked: true);
  }

  static Future<Post> createPost(String body) async {
    await Future.delayed(const Duration(seconds: 1));
    return Post(id: DateTime.now().millisecondsSinceEpoch.toString(), body: body, isLiked: false);
  }
}

/// A proxy class for [Post] is a wrapper for the original data class that adds reactivity.
///
/// Proxies also automatically listen to incoming events from dispatchers (see [PostDispatcher] below) and can update
/// their internal value accordingly.
class PostProxy extends ValueProxy<Post> {
  PostProxy(super.value);

  // By leveraging computed properties here, we can "scope" reactivity in the consumers easily, and also avoid having
  // to unwrap this proxy in the UI code.
  late final body = $computed(() => value.body);
  late final isLiked = $computed(() => value.isLiked);
}

/// A post dispatcher acts as a central hub for all post-related things.
///
/// This is usually a singleton in your app.
///
/// Post dispatcher is responsible for creating proxies, and providing mutation methods. In general, I use this as a
/// central place to put everything that is related to posts, including value sources.
///
/// Dispatchers have to be registered in a DI container. See the bottom of this file for an example on how I approach
/// this.
class PostDispatcher extends ValueDispatcher<Post> {
  PostDispatcher();

  @override
  ValueProxy<Post> createProxy(Post value) => PostProxy(value);

  @override
  Object identify(Post value) => value.id;

  // I usually put value sources in the dispatcher as well, so that everything is in one place. But it's not required,
  // as the value sources can be created independently as well.
  PostListSource createPostListSource() => PostListSource();

  // Notice here how we can provide an initial value. This is useful when navigating to a detail page from a list page,
  // so that we can show the data immediately without waiting for the network. If the initial value is not provided, we
  // can try to "fork" an existing proxy with the same id from other sources, so that we can reuse already loaded
  // data, and avoid a blank state.
  PostSingleSource createPostSingleSource(String postId, {Post? initialValue}) =>
      PostSingleSource(postId, initialValue: initialValue ?? this[postId]);

  // Mutations go here as well. They can be async, and can also have optimistic updates.

  Future<Post> like(String postId) async {
    // A mutation should provide the operationId (can be any hashable object), and the parameters. If there are
    // multiple parameters, it's easiest to wrap them in a tuple.
    return $mutation(
      #like,
      postId,
      () async {
        // The actual mutation function. This is where you call real "side effect" code, like APIs or database
        // operations.
        //
        // If the returned type is either [Post] or [List<Post>], the dispatcher will automatically emit
        // [ValueUpdateEvent]s for the updated items, and all proxies will update their values accordingly.
        final updatedPost = await PostApi.likePost(postId);
        return updatedPost;
      },
      optimisticUpdate: () {
        // This is an optional function that can provide an optimistic update. It should return a tuple of
        // (oldValue, newValue). If it's impossible to provide an optimistic update, just return null.
        //
        // Here we try to find an existing post with that id, and if found, we return a copy of it with
        // `isLiked` set to true (and the old value as well, so that it can be reverted if the mutation fails).
        final existing = this[postId];
        if (existing != null) return (existing, existing.copyWith(isLiked: true));
        return null;
      },
    );
  }

  Future<Post> create(String body) async {
    return $mutation(
      #create,
      body,
      () async {
        final newPost = await PostApi.createPost(body);

        // Here, we dispatch a create event manually, since by default, mutations will dispatch "update" events.
        dispatchCreate(this, newPost);
        return newPost;
      },
      // We want to handle the update manually here.
      automaticallyDispatchUpdates: false,
    );
  }
}

/// A value source for a list of posts.
///
/// Note that the value sources will contain a list of proxies automatically, so you don't have to deal with that
/// manually. Also, they have to be disposed when no longer needed. If using `stack` completely, you can use
/// `useDisposable` in hook widgets to manage the lifecycle automatically. Proxies are also disposed automatically
/// once the value source is disposed. If you need to "fork" a proxy to keep it alive longer, you can use
/// `ValueDispatcher.fork`.
///
/// Cool thing is that value sources can react to events from dispatchers as well. For example, by default, list
/// sources will react to [ValueDeleteEvent]s and remove the deleted item from the list automatically. Here, we want
/// to insert a post when a post is created, so we override [$onValueEvent] to handle that.
class PostListSource extends ListValueSource<Post, PostProxy> {
  PostListSource({super.initialValue}) : super(logger: Logger('PostListSource'));

  @override
  Future<(List<Post>, Object?, int?)> performLoad(Object? token) async {
    // Here, `Object? token` can be used for pagination. If it's not needed, you can return null.
    // The third return value is the total item count, if known. This can be used in the UI for things like
    // accurate scrollbars.
    //
    // If a pagination token is returned, it'll be passed to the next call of `performLoad` when more items
    // are requested.
    final posts = await PostApi.fetchPosts();
    return (posts, null, null);
  }

  @override
  void $onValueEvent(ValueEvent<Post> event) {
    if (event is ValueCreateEvent<Post>) {
      // Insert the new post at the start of the list.
      $insertAt(0, event.value);
    } else {
      // Defer to the default implementation for other events.
      super.$onValueEvent(event);
    }
  }
}

/// A value source for a single post.
///
/// Here we don't really do anything special, but this shows how you can create value sources that take parameters
/// in their constructors.
class PostSingleSource extends SingleValueSource<Post, PostProxy> {
  PostSingleSource(this.postId, {super.initialValue}) : super(logger: Logger('PostSingleSource'));

  final String postId;

  @override
  Future<Post> performLoad() async {
    return PostApi.fetchPost(postId);
  }
}

// We're done with the entire setup! Now it's time for consuming this in a Flutter app.

// This is a utility that I use to have good DX with DI. You can add other stuff into [DiExtensions] as needed.

final _dispatchers = Dispatchers._();

class Dispatchers {
  Dispatchers._();

  PostDispatcher get post => di.get<ValueDispatcher<Post>>() as PostDispatcher;
}

extension DiExtensions on GetIt {
  Dispatchers get dispatchers => _dispatchers;
}

/// A method to setup DI. Make sure that dispatchers are registered as follows.
///
/// Once this is done, you can access the dispatcher anywhere in the app via `di.dispatchers.post`.
void setupDi() {
  di.registerSingleton<ValueDispatcher<Post>>(PostDispatcher());
}

class MainPage extends HookWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We "scope" this source to the lifecycle of this widget using [useDisposable]. This way, it'll be disposed
    // automatically when the widget is removed from the tree.
    final source = useDisposable(() => di.dispatchers.post.createPostListSource());
    useCallOnce(source.load);

    // Usually, you would create a separate widget that wraps [ValueSourceBuilder] to provide common UI for
    // loading/error states, as well as handling reactivity.
    return ValueSourceBuilder(
      valueSource: source,
      valueBuilder: (context, isLoading, error) {
        // ...
        return Placeholder();
      },
    );
  }
}

class SinglePostPage extends StatelessWidget {
  const SinglePostPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    // Note how [createPostSingleSource] is created. This means that if there's already a [PostListSource] or another
    // [PostSingleSource] that has loaded the post with the same id, the data will be forked and reused here to provide
    // the initial value.
    final source = useDisposable(() => di.dispatchers.post.createPostSingleSource(postId));
    useCallOnce(source.load);

    final hasValue = useExistingSignal(source.hasValueSignal).value;
    if (!hasValue) {
      return const CircularProgressIndicator();
    }

    final value = source.value!;
    return Card(
      child: Column(
        children: [
          Watch((_) => Text(value.body.value)),
          Watch(
            (_) => IconButton(
              icon: Icon(value.isLiked.value ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                // When this is called, the mutation will be executed, and the result is propagated automatically to
                // all proxies with the same postId.
                di.dispatchers.post.like(postId);
              },
            ),
          ),
        ],
      ),
    );
  }
}
