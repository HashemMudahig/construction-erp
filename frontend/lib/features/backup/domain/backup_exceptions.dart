class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupValidationException extends BackupException {
  const BackupValidationException(super.message);
}

class BackupBusyException extends BackupException {
  const BackupBusyException()
      : super('Another backup operation is in progress.');
}
