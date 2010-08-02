void synchronizer_start();
void synchronizer_stop();
void synchronizer_run();

NSString *user_file_path(NSString *filename);
NSString *read_user_file(NSString *filename);
NSString *read_bundle_file(NSString *filename);
NSString *script_command(NSString *scriptName, NSDictionary *params);
