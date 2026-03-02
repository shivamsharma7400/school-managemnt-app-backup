

import 'package:flutter/foundation.dart';

class DriveHelper {
  /// Converts a Google Drive sharing URL into a direct image/file URL.
  /// 
  /// Supports formats:
  /// - https://drive.google.com/file/d/FILE_ID/view
  /// - https://drive.google.com/open?id=FILE_ID
  /// - https://docs.google.com/file/d/FILE_ID/edit
  static String? getDirectDriveUrl(String originalUrl) {
    if (originalUrl.isEmpty) return null;

    // Check if it's already a direct link or not a drive link
    if (!originalUrl.contains('drive.google.com') && !originalUrl.contains('docs.google.com')) {
      return originalUrl;
    }

    try {
      final RegExp regExp = RegExp(r'(?:/d/|id=)([\w-]+)');
      final Iterable<RegExpMatch> matches = regExp.allMatches(originalUrl);

      if (matches.isNotEmpty) {
        final String? fileId = matches.first.group(1);
        if (fileId != null) {
          final driveUrl = 'https://drive.google.com/thumbnail?id=$fileId&sz=w1000';
          
          // On web, we MUST use a robust image proxy like weserv (wsrv.nl) 
          // to bypass CORS when fetching bytes for PDF generation.
          if (kIsWeb) {
            return 'https://wsrv.nl/?url=${Uri.encodeComponent(driveUrl)}';
          }
          
          return driveUrl;
        }
      }
    } catch (e) {
      // Return original if parsing fails
      return originalUrl;
    }

    return originalUrl;
  }
}
