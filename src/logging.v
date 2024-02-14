module logging

import vseryakov.syslog

const exit_failure = 1

interface LogHandler {
	write(string, bool)
}

struct StdoutHandler {}

fn (s StdoutHandler) write(message string, error bool) {
	if error {
		eprintln(message)
	} else {
		println(message)
	}
}

struct SyslogHandler {}

fn SyslogHandler.new(prog_name string) SyslogHandler {
	syslog.open(prog_name, syslog.log_pid, syslog.log_user)
	return SyslogHandler{}
}

fn (s SyslogHandler) write(message string, error bool) {
	level := if error { syslog.log_err } else { syslog.log_info }
	syslog.log(level, message)
}

pub struct Logger {
	handler LogHandler
}

pub fn Logger.stdout() Logger {
	return Logger{StdoutHandler{}}
}

pub fn Logger.syslog(prog_name string) Logger {
	return Logger{SyslogHandler.new(prog_name)}
}

pub fn (l Logger) info(message string) {
	l.handler.write(message, false)
}

@[noreturn]
pub fn (l Logger) die(message string) {
	l.handler.write(message, true)
	exit(logging.exit_failure)
}
