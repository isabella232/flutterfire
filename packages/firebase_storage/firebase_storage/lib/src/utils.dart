/// Returns a bucket from a given `gs://` URL.
String bucketFromGoogleStorageUrl(String url) {
  assert(url.startsWith('gs://'));
  int stopIndex = url.indexOf('/', 5);
  int stop = stopIndex == -1 ? url.length : stopIndex;
  return url.substring(5, stop);
}

/// Returns a path from a given `gs://` URL.
/// 
/// If no path exists, the root path will be returned.
String pathFromGoogleStorageUrl(String url) {
  assert(url.startsWith('gs://'));
  int stopIndex = url.indexOf('/', 5);
  if (stopIndex == -1) return '/';
  return url.substring(stopIndex + 1, url.length);
}
