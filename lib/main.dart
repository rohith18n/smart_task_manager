import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/profile/presentation/bloc/profile_event.dart';
import 'features/profile/presentation/bloc/profile_state.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FCM Background Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint(
      'Firebase initialization notice: $e (Operating in offline-first mode)',
    );
  }

  // Initialize Dependency Injection container
  await initServiceLocator();

  // Trigger initial auth check
  final authBloc = sl<AuthBloc>();
  authBloc.add(const AuthCheckRequestedEvent());

  // Warm start for cached Firebase session
  final cachedUser = () {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }();

  if (cachedUser != null) {
    final uid = cachedUser.uid;
    sl<ApiClient>().setUserId(uid);
    sl<ThemeCubit>().setUserId(uid);
    sl<ProfileBloc>().add(LoadProfileEvent(
      uid,
      fallbackEmail: cachedUser.email,
      fallbackName: cachedUser.displayName,
    ));
    sl<TaskBloc>().add(LoadTasksEvent(uid));
  }

  final router = AppRouter.createRouter(authBloc);

  // Initialize Notifications
  try {
    await sl<NotificationService>().initialize();
  } catch (e) {
    debugPrint('Notification service init notice: $e');
  }

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {
  final dynamic router;

  const MyApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    final authBloc = sl<AuthBloc>();
    final routerConfig = router ?? AppRouter.createRouter(authBloc);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ProfileBloc>.value(value: sl<ProfileBloc>()),
        BlocProvider<TaskBloc>.value(value: sl<TaskBloc>()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.isAuthenticated && state.user != null) {
                final userId = state.user!.id;
                sl<ApiClient>().setUserId(userId);
                sl<ThemeCubit>().setUserId(userId);
                sl<NotificationService>().saveTokenToUser(userId);

                // Fetch user profile from Firestore
                context.read<ProfileBloc>().add(
                      LoadProfileEvent(
                        userId,
                        fallbackEmail: state.user!.email,
                        fallbackName: state.user!.displayName,
                      ),
                    );

                context.read<TaskBloc>().add(LoadTasksEvent(userId));
              } else if (state.status == AuthStatus.unauthenticated) {
                sl<ApiClient>().setUserId(null);
                sl<ThemeCubit>().setUserId(null);
                context.read<TaskBloc>().add(const LoadTasksEvent(null));
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, profileState) {
              // Auto-apply saved theme from Firestore user profile
              if (profileState.status == ProfileStatus.success &&
                  profileState.profile != null) {
                context.read<ThemeCubit>().setThemeFromString(
                      profileState.profile!.themeMode,
                      persist: false,
                    );
              }
            },
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: AppConstants.appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: routerConfig,
            );
          },
        ),
      ),
    );
  }
}
