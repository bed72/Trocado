enum LoggerLevelConstant {
  error('ERROR'),
  debug('DEBUG'),
  warning('WARNING'),
  verbose('VERBOSE'),
  information('INFO'),
  critical('CRITICAL');

  final String type;

  const LoggerLevelConstant(this.type);
}
