class DbException implements Exception {
  String cause;
  DbException(this.cause);
}
