/// Git Integration Module
///
/// Provides comprehensive version control functionality with:
/// - Git operations (init, clone, commit, push, pull, merge)
/// - Visual diff viewer (side-by-side, inline)
/// - Branch management
/// - Commit history and blame
/// - Merge conflict resolution
library git_integration;

// Domain Layer
export 'src/domain/entities/git_repository.dart';
export 'src/domain/entities/git_commit.dart';
export 'src/domain/entities/git_branch.dart';
export 'src/domain/entities/git_remote.dart';
export 'src/domain/entities/git_stash.dart';
export 'src/domain/entities/file_change.dart';
export 'src/domain/entities/merge_conflict.dart';
export 'src/domain/entities/diff_hunk.dart';
export 'src/domain/entities/blame_line.dart';

export 'src/domain/value_objects/repository_path.dart';
export 'src/domain/value_objects/commit_hash.dart';
export 'src/domain/value_objects/branch_name.dart';
export 'src/domain/value_objects/remote_name.dart';
export 'src/domain/value_objects/commit_message.dart';
export 'src/domain/value_objects/git_author.dart';
export 'src/domain/value_objects/file_status.dart';

export 'src/domain/repositories/i_git_repository.dart';
export 'src/domain/repositories/i_diff_repository.dart';
export 'src/domain/repositories/i_credential_repository.dart';

export 'src/domain/services/merge_strategy_selector.dart';
export 'src/domain/services/conflict_detector.dart';

export 'src/domain/events/git_domain_events.dart';
export 'src/domain/failures/git_failures.dart';

// Application Layer
export 'src/application/services/git_service.dart';
export 'src/application/services/diff_service.dart';
export 'src/application/services/blame_service.dart';
export 'src/application/services/merge_service.dart';

// Use Cases
export 'src/application/use_cases/init_repository_use_case.dart';
export 'src/application/use_cases/clone_repository_use_case.dart';
export 'src/application/use_cases/get_repository_status_use_case.dart';
export 'src/application/use_cases/stage_files_use_case.dart';
export 'src/application/use_cases/unstage_files_use_case.dart';
export 'src/application/use_cases/commit_changes_use_case.dart';
export 'src/application/use_cases/create_branch_use_case.dart';
export 'src/application/use_cases/checkout_branch_use_case.dart';
export 'src/application/use_cases/delete_branch_use_case.dart';
export 'src/application/use_cases/merge_branch_use_case.dart';
export 'src/application/use_cases/push_changes_use_case.dart';
export 'src/application/use_cases/pull_changes_use_case.dart';
export 'src/application/use_cases/fetch_changes_use_case.dart';
export 'src/application/use_cases/get_commit_history_use_case.dart';
export 'src/application/use_cases/get_diff_use_case.dart';
export 'src/application/use_cases/add_remote_use_case.dart';
export 'src/application/use_cases/remove_remote_use_case.dart';
export 'src/application/use_cases/stash_changes_use_case.dart';
export 'src/application/use_cases/apply_stash_use_case.dart';
export 'src/application/use_cases/rebase_branch_use_case.dart';
export 'src/application/use_cases/get_blame_use_case.dart';
export 'src/application/use_cases/resolve_conflict_use_case.dart';

// Infrastructure Layer
export 'src/infrastructure/repositories/git_cli_repository.dart';
export 'src/infrastructure/repositories/diff_repository_impl.dart';
export 'src/infrastructure/repositories/credential_repository_impl.dart';
export 'src/infrastructure/adapters/git_command_adapter.dart';
export 'src/infrastructure/adapters/git_parser_adapter.dart';
export 'src/infrastructure/infrastructure_module.dart';

// Dependency Injection
export 'src/injection.dart';
