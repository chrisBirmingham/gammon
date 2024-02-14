module main

import cli
import json
import logging
import os
import porkbun
import time
import v.vmod

const exit_failure = 1
const service_name = 'gammond'

struct Config {
	domain string @[required]
	api_key string @[required]
	secret_api_key string @[required]
}

fn is_daemon() bool {
	prog := os.base(os.args[0])
	return prog == service_name
}

struct App {
	api porkbun.Api
	logger logging.Logger
}

fn App.new(api porkbun.Api, logger logging.Logger) App {
	return App{api, logger}
}

fn (a App) process_domain(ip_address string) {
	a.logger.info('Retrieving A DNS record')
	records := a.api.retrieve_records('A') or {
		a.logger.die('Failed to retrive Domain A record. Reason: ${err}')
	}

	if records.len > 1 {
		a.logger.die('Found more than one A record for domain. Exiting')
	}

	record := records[0] or {
		a.logger.info("A record doesn't exist. Creating")
		a.api.create_record('A', ip_address) or {
			a.logger.die('Failed to create new A record. Reason: ${err}')
		}
		a.logger.info('Successfully created A record')
		return
	}

	if ip_address == record.get_ip_address() {
		a.logger.info('Current IP address and stored IP address match. Skipping update')
		return
	}

	a.logger.info('New IP address is ${ip_address}')
	a.api.edit_record(record.get_id(), record.get_type(), ip_address) or {
		a.logger.die('Failed to update IP address. Reason: ${err}')
	}
	a.logger.info('Successfully updated IP address')
}

fn (a App) get_ip_address() string {
	a.logger.info('Fetching public IP address')
	ip_address := a.api.ping() or {
		a.logger.die('Failed to get IP address. Reason: ${err}')
	}
	return ip_address
}

fn read_config_file(config_file string, logger logging.Logger) Config {
	config_str := os.read_file(config_file) or {
		logger.die("Counldn't open config file ${config_file}. Reason: ${err}")
	}

	config := json.decode(Config, config_str) or {
		logger.die('Invalid config file provided. Reason: ${err}')
	}

	return config
}

fn run_application(cmd cli.Command) ! {
	logger := if is_daemon() {
			logging.Logger.syslog(service_name)
		} else {
			logging.Logger.stdout()
		}

	config_file := cmd.flags.get_string('config-file')!
	config := read_config_file(config_file, logger)

	// If test is supplied and we've gotten to this point, the config is "valid"
	test := cmd.flags.get_bool('test')!
	if test {
		logger.info('Config is valid')
		return
	}

	api := porkbun.Api.new(
		config.domain,
		config.api_key,
		config.secret_api_key
	)

	app := App.new(api, logger)

	if !is_daemon() {
		mut ip_address := cmd.flags.get_string('ip')!
		
		if ip_address == '' {
			ip_address = app.get_ip_address()
		}

		app.process_domain(ip_address)
	} else {
		duration := time.Duration(10 * time.minute)

		for {
			ip_address := app.get_ip_address()
			app.process_domain(ip_address)
			time.sleep(duration)
		}
	}
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or {
		eprintln('Failure to read v.mod file. Reason: ${err.msg()}')
		exit(exit_failure)
	}

	mut app := cli.Command{
		name: os.args[0]
		description: mod.description
		execute: run_application
		posix_mode: true
		disable_man: true
		version: mod.version
	}

	app.add_flag(cli.Flag{
		flag: .string
		required: true
		name: 'config-file'
		abbrev: 'c'
		description: 'Path to config file'
	})

	app.add_flag(cli.Flag{
		flag: .bool
		required: false
		name: 'test'
		abbrev: 't'
		description: 'Checks the validity of the provided config file'
		default_value: ['false']
	})

	if !is_daemon() {
		app.add_flag(cli.Flag{
			flag: .string
			required: false
			name: 'ip'
			description: 'Bypass IP address lookup and set IP to option provided'
			default_value: ['']
		})
	}

	app.setup()
	app.parse(os.args)
}
