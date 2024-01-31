module logging

import log

const exit_failure = 1

pub struct Logger {
	mut:
		logger log.Log
}

pub fn Logger.new(level log.Level) Logger {
	mut l := log.Log{}
	l.set_level(level)
	return Logger{l}
}

pub fn (mut l Logger) set_log_file(log_file string) {
	l.logger.set_full_logpath(log_file)
}

@[noreturn]
pub fn (mut l Logger) die(message string) {
	l.logger.error(message)
	exit(exit_failure)
}

pub fn (mut l Logger) info(message string) {
	l.logger.info(message)
}
