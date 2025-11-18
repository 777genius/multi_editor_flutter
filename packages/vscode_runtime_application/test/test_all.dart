/// Master test file that imports all test suites
///
/// Run all tests with: dart test test/test_all.dart

import 'handlers/install_runtime_command_handler_test.dart' as install_handler_test;
import 'handlers/cancel_installation_command_handler_test.dart' as cancel_handler_test;
import 'handlers/get_runtime_status_query_handler_test.dart' as status_handler_test;

void main() {
  install_handler_test.main();
  cancel_handler_test.main();
  status_handler_test.main();
}
