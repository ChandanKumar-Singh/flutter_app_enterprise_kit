import 'package:enterprise_kit/core/bootstrap/app_bootstrap.dart';
import 'package:enterprise_kit/core/bootstrap/app_flavor.dart';

// ─── Entry points per flavor ──────────────────────────────────────────────────
void main()        => AppBootstrap.run(AppFlavor.production);
void mainDev()     => AppBootstrap.run(AppFlavor.development);
void mainStaging() => AppBootstrap.run(AppFlavor.staging);
