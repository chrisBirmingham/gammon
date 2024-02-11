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

pub struct Logger {
	mut: handler LogHandler
}

pub fn Logger.stdout() Logger {
	return Logger{StdoutHandler{}}
}

pub fn Logger.file(file_path string) Logger {
	return Logger{FileHandler.new(file_path)}
}

pub fn (mut l Logger) info(message string) {
	l.handler.write(message)
}

@[noreturn]
pub fn (mut l Logger) die(message string) {
	l.handler.write(message)
	exit(exit_failure)
}
