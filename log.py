import sys

class Log(object):
    DEBUG = 0
    INFO = 1
    WARNING = 2
    ERROR = 3
    FATAL = 4

    LEVEL_STR = [
        "DEBUG",
        "INFO",
        "WARNING",
        "ERROR",
        "FATAL"
    ]

    def __init__(self, path=None, level=WARNING):
        self.file = sys.stdout if path is None else open(path, 'a')
        self.log_level = level

    def log(self, level, *message):
        if level >= self.log_level:
            self.file.write(
                self.LEVEL_STR[level] + ': ' + ' '.join([str(m) for m in message]) + '\n')
    def logf(self, level, template, *args):
        self.log(level, template.format(*args))

    def info(self, *message):
        self.log(self.INFO, *message)
    def infof(self, template, *args):
        self.logf(self.INFO, template, *args)
    def debug(self, *message):
        self.log(self.DEBUG, *message)
    def debugf(self, template, *args):
        self.logf(self.DEBUG, template, *args)
    def warning(self, *message):
        self.log(self.WARNING, *message)
    def warningf(self, template, *args):
        self.logf(self.WARNING, template, *args)
    def error(self, *message):
        self.log(self.ERROR, *message)
    def errorf(self, template, *args):
        self.logf(self.ERROR, template, *args)
    def fatal(self, *message):
        self.log(self.FATAL, *message)
    def fatalf(self, template, *args):
        self.logf(self.FATAL, template, *args)

logger = None
def init_global_log(*args, **kwargs):
    global logger
    logger = Log(*args, **kwargs)

def info(*message):
    logger.info(*message)
def infof(template, *args):
    logger.infof(template, *args)
def debug(*message):
    logger.debug(*message)
def debugf(template, *args):
    logger.debugf(template, *args)
def warning(*message):
    logger.warning(*message)
def warningf(template, *args):
    logger.warningf(template, *args)
def error(*message):
    logger.error(*message)
def errorf(template, *args):
    logger.errorf(template, *args)
def fatal(*message):
    logger.fatal(*message)
def fatalf(template, *args):
    logger.fatalf(template, *args)
