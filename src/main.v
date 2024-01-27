module main

import cli
import os
import json
import porkbun
import v.vmod

const exit_failure = 1

struct Config {
	domain string @[required]
	api_key string @[required]
	secret_api_key string @[required]
}

@[noreturn]
fn die(message string) {
	eprintln(message)
	exit(exit_failure)
}

fn read_config_file(config_file string) Config {
	config_str := os.read_file(config_file) or {
		die("Counldn't open config file ${config_file}. Reason: ${err}")
	}

	config := json.decode(Config, config_str) or {
		die('Invalid config file provided. Reason: ${err}')
	}

	return config
}

fn run_application(cmd cli.Command) ! {
	config_file := cmd.flags.get_string('file')!
	config := read_config_file(config_file)

	api := porkbun.Api.new(
		config.domain,
		config.api_key,
		config.secret_api_key
	)

	ip_address := api.ping() or {
		die('Failed to get IP address. Reason: ${err}')
	}

	records := api.retrieve_records('A') or {
		die('Failed to retrive Domain A records. Reason: ${err}')
	}

	if records.len > 1 {
		die('Found more than one A record for domain. Exiting')
	}

	record := records[0] or {
		println("A record doesn't exist. Creating")
		api.create_record('A', ip_address) or {
			die('Failed to create new A record. Reason: ${err}')
		}
		println('Successfully created A record')
		return
	}

	if ip_address == record.get_ip_address() {
		println('Current IP address and stored IP address match. Skipping update')
		return
	}

	println('IP addresses are different. Updating')
	api.edit_record('A', ip_address) or {
		die('Failed to update IP address. Reason: ${err}')
	}
	println('Successfully updated IP address')
}

fn main() {
	mod := vmod.decode(@VMOD_FILE) or {
		die('Failure to read v.mod file. Reason: ${err.msg()}')
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
		required: false
		name: 'file'
		abbrev: 'f'
		description: 'Path to config file'
		default_value: ['/etc/${mod.name}/config.yaml']
	})

	app.setup()
	app.parse(os.args)
}
