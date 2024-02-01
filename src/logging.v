module logging

import os
import time

const exit_failure = 1

interface LogHandler {
	mut: write(string)
}

struct StdoutHandler {}

fn (mut s StdoutHandler) write(message string) {
	println(message)
}

pub struct FileHandler {
	mut: fp os.File
}

pub fn FileHandler.new(log_path string) FileHandler {
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

pub struct Logger {
	mut: handlers []LogHandler
}

pub fn Logger.default_logger() Logger {
	return Logger{[StdoutHandler{}]}
}

pub fn (mut l Logger) add_handler(handler LogHandler) {
	l.handlers << handler
}

pub fn (mut l Logger) info(message string) {
	for mut handler in l.handlers {
		handler.write(message)
	}
}

@[noreturn]
pub fn (mut l Logger) die(message string) {
	for mut handler in l.handlers {
		handler.write(message)
	}
	exit(exit_failure)
}
