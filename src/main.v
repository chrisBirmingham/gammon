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
	return os.args[0] == service_name
}

fn process_domain(api porkbun.Api, ip_address string, mut logger logging.Logger) {
	logger.info('Retrieving A DNS record')
	records := api.retrieve_records('A') or {
		logger.die('Failed to retrive Domain A record. Reason: ${err}')
	}

	if records.len > 1 {
		logger.die('Found more than one A record for domain. Exiting')
	}

	record := records[0] or {
		logger.info("A record doesn't exist. Creating")
		api.create_record('A', ip_address) or {
			logger.die('Failed to create new A record. Reason: ${err}')
		}
		logger.info('Successfully created A record')
		return
	}

	if ip_address == record.get_ip_address() {
		logger.info('Current IP address and stored IP address match. Skipping update')
		return
	}

	logger.info('New IP address is ${ip_address}')
	api.edit_record(record.get_id(), record.get_type(), ip_address) or {
		logger.die('Failed to update IP address. Reason: ${err}')
	}
	logger.info('Successfully updated IP address')
}

fn read_config_file(config_file string, mut logger logging.Logger) Config {
	config_str := os.read_file(config_file) or {
		logger.die("Counldn't open config file ${config_file}. Reason: ${err}")
	}

	config := json.decode(Config, config_str) or {
		logger.die('Invalid config file provided. Reason: ${err}')
	}

	return config
}

fn get_ip_address(api porkbun.Api, mut logger logging.Logger) string {
		logger.info('Fetching public IP address')
		ip_address := api.ping() or {
			logger.die('Failed to get IP address. Reason: ${err}')
		}
		return ip_address
}

fn run_application(cmd cli.Command) ! {
	config_file := cmd.flags.get_string('config-file')!
	log_file := cmd.flags.get_string('log')!
	mut logger := logging.Logger.default_logger()

	if log_file != '' {
		file_handler := logging.FileHandler.new(log_file)
		logger.add_handler(file_handler)
	}

	config := read_config_file(config_file, mut logger)

	api := porkbun.Api.new(
		config.domain,
		config.api_key,
		config.secret_api_key
	)

	if !is_daemon() {
		mut ip_address := cmd.flags.get_string('ip')!
		
		if ip_address == '' {
			ip_address = get_ip_address(api, mut logger)
		}

		process_domain(api, ip_address, mut logger)
	} else {
		duration := time.Duration(10 * time.minute)
		for {
			ip_address := get_ip_address(api, mut logger) 
			process_domain(api, ip_address, mut logger)
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
		name: mod.name
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

	if !is_daemon() {
		app.add_flag(cli.Flag{
			flag: .string
			required: false
			name: 'ip'
			description: 'Bypass IP address lookup and set IP to option provided'
			default_value: ['']
		})
	}

	app.add_flag(cli.Flag{
		flag: .string
		required: false
		name: 'log'
		abbrev: 'l'
		description: 'Specify log file to write too'
		default_value: ['']
	})

	app.setup()
	app.parse(os.args)
}
