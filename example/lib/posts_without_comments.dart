import 'package:flutter/material.dart';
import 'package:stack/stack.dart';

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

class PostProxy extends ValueProxy<Post> {
  PostProxy(super.value);

  late final body = $computed(() => value.body);
  late final isLiked = $computed(() => value.isLiked);
}

class PostDispatcher extends ValueDispatcher<Post> {
  PostDispatcher();

  @override
  ValueProxy<Post> createProxy(Post value) => PostProxy(value);

  @override
  Object identify(Post value) => value.id;

  PostListSource createPostListSource() => PostListSource();
  PostSingleSource createPostSingleSource(String postId, {Post? initialValue}) =>
      PostSingleSource(postId, initialValue: initialValue ?? this[postId]);

  Future<Post> like(String postId) async {
    return $mutation(
      #like,
      postId,
      () async {
        final updatedPost = await PostApi.likePost(postId);
        return updatedPost;
      },
      optimisticUpdate: () {
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

        dispatchCreate(this, newPost);
        return newPost;
      },
      automaticallyDispatchUpdates: false,
    );
  }
}

class PostListSource extends ListValueSource<Post, PostProxy> {
  PostListSource({super.initialValue}) : super(logger: Logger('PostListSource'));

  @override
  Future<(List<Post>, Object?, int?)> performLoad(Object? token) async {
    final posts = await PostApi.fetchPosts();
    return (posts, null, null);
  }

  @override
  void $onValueEvent(ValueEvent<Post> event) {
    if (event is ValueCreateEvent<Post>) {
      $insertAt(0, event.value);
    } else {
      super.$onValueEvent(event);
    }
  }
}

class PostSingleSource extends SingleValueSource<Post, PostProxy> {
  PostSingleSource(this.postId, {super.initialValue}) : super(logger: Logger('PostSingleSource'));

  final String postId;

  @override
  Future<Post> performLoad() async {
    return PostApi.fetchPost(postId);
  }
}

final _dispatchers = Dispatchers._();

class Dispatchers {
  Dispatchers._();

  PostDispatcher get post => di.get<ValueDispatcher<Post>>() as PostDispatcher;
}

extension DiExtensions on GetIt {
  Dispatchers get dispatchers => _dispatchers;
}

void setupDi() {
  di.registerSingleton<ValueDispatcher<Post>>(PostDispatcher());
}

class MainPage extends HookWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final source = useDisposable(() => di.dispatchers.post.createPostListSource());
    useCallOnce(source.load);

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
    final source = useDisposable(() => di.dispatchers.post.createPostSingleSource(postId));
    final hasValue = useExistingSignal(source.hasValueSignal).value;
    useCallOnce(source.load);

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
              onPressed: () => di.dispatchers.post.like(postId),
            ),
          ),
        ],
      ),
    );
  }
}
