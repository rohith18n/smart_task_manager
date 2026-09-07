import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_state.dart';

class TaskListOfflineBanner extends StatelessWidget {
  const TaskListOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      buildWhen: (prev, curr) => prev.isOnline != curr.isOnline,
      builder: (context, state) {
        if (state.isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFD97706),
          child: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline. Showing cached tasks. Changes will auto-sync when online.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
