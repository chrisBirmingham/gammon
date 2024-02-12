module logging

import os
import time
import vseryakov.syslog

const exit_failure = 1

interface LogHandler {
	mut: write(string)
}

struct StdoutHandler {}

fn (mut s StdoutHandler) write(message string) {
	println(message)
}

struct FileHandler {
	mut: fp os.File
}

fn FileHandler.new(log_path string) FileHandler {
	mut fp := os.open_append(log_path) or {
		panic(err)
	}
	return FileHandler{fp}
}

fn (mut f FileHandler) write(message string) {
	date := time.now().format_ss()
	f.fp.write_string("[${date}] ${message}\n") or {
		panic(err)
	}
}

struct SyslogHandler {}

fn SyslogHandler.new(prog_name string) SyslogHandler {
  syslog.open(prog_name, syslog.log_pid, syslog.log_user)
  return SyslogHandler{}
}

fn (mut s SyslogHandler) write(message string) {
  syslog.info(message)
}

pub struct Logger {
	mut: handler LogHandler
}

pub fn Logger.stdout() Logger {
	return Logger{StdoutHandler{}}
}

pub fn Logger.file(file_path string) Logger {
	return Logger{FileHandler.new(file_path)}
}

pub fn Logger.syslog(prog_name string) Logger {
  return Logger{SyslogHandler.new(prog_name)}
}

pub fn (mut l Logger) info(message string) {
	l.handler.write(message)
}

@[noreturn]
pub fn (mut l Logger) die(message string) {
	l.handler.write(message)
	exit(exit_failure)
}
