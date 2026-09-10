import 'dart:async';

import 'package:app_links/app_links.dart';

/// Cold start + warm links. Implemented with `app_links` in production.
abstract class IncomingLinkSource {
  Future<Uri?> getInitialLink();

  Stream<Uri> get uriLinkStream;
}

class IncomingLinkSourceImpl implements IncomingLinkSource {
  IncomingLinkSourceImpl([AppLinks? appLinks])
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}
