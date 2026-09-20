import 'package:go_router/go_router.dart';

import '../pages/paged_post_page.dart';
import '../pages/post_detail_page.dart';
import '../pages/post_list_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PostListPage(),
    ),
    GoRoute(
      path: '/paged',
      builder: (context, state) => const PagedPostPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
        return PostDetailPage(postId: id);
      },
    ),
  ],
);
