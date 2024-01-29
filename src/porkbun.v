module porkbun

import json
import net.http

const api_url = 'https://porkbun.com/api/json/v3'

enum Status {
	success
	error
}

struct StatusResponse {
	status Status @[required]
}

struct ErrorResponse {
	status Status @[required]
	message string @[required]
}

struct AuthRequest {
	api_key string @[json: 'apikey']
	secret_api_key string @[json: 'secretapikey']
}

struct PingResponse {
	status Status @[required]
	ip string @[json: 'yourIp'; required]
}

struct DnsRecord {
	id string @[required]
	name string @[required]
	record_type string @[json: 'type'; required]
	ttl string @[required]
	prio string
	notes string
	content string @[required]
}

pub fn (d DnsRecord) get_ip_address() string {
	return d.content
}

struct RetrieveResponse {
	status Status @[required]
	records []DnsRecord @[required]
}

struct CreateRequest {
	api_key string @[json: 'apikey']
	secret_api_key string @[json: 'secretapikey']
	record_type string @[json: 'type']
	content string
}

struct EditRequest {
	api_key string @[json: 'apikey']
	secret_api_key string @[json: 'secretapikey']
	content string
}

struct Api {
	domain string
	api_key string
	secret_api_key string
}

pub fn Api.new(domain string, api_key string, secret_api_key string) Api {
	return Api{domain, api_key, secret_api_key}
}

fn (a Api) get_error_response(body string) string {
	err_response := json.decode(ErrorResponse, body) or {
		panic('Failed to decode error response ${err}')
	}

	return err_response.message
}

fn (a Api) send_request(endpoint string, body string) !string {
	url := '${api_url}/${endpoint}'

	res := http.post_json(url, body) or {
		return error('Failed to contact api endpoint ${err}')
	}

	if res.status_code != 200 {
		error('Non 200 status code returned. Status: ${res.status_code}. Message: ${a.get_error_response(res.body)}')
	}

	return res.body
}

pub fn (a Api) ping() !string {
	ping := AuthRequest{a.api_key, a.secret_api_key}
	res := a.send_request('ping', json.encode(ping)) or {
		return err
	}

	json_res := json.decode(PingResponse, res) or {
		return error('Failed to decode api response. Reason: ${err}')
	}

	if json_res.status == .error {
		error('Received an error status while getting IP address')
	}

	return json_res.ip
}

pub fn (a Api) retrieve_records(record_type string) ![]DnsRecord {
	ping := AuthRequest{a.api_key, a.secret_api_key}
	url := 'dns/retrieveByNameType/${a.domain}/${record_type}'
	res := a.send_request(url, json.encode(ping)) or {
		return err
	}

	json_res := json.decode(RetrieveResponse, res) or {
		return error('Failed to decode api response. Reason: ${err}')
	}

	if json_res.status == .error {
		error('Received an error status while getting DNS Records')
	}

	return json_res.records
}

pub fn (a Api) create_record(record_type string, content string) ! {
	url := 'dns/create/${a.domain}'

	create_req := CreateRequest{
		a.api_key
		a.secret_api_key
		record_type,
		content
	}

	res := a.send_request(url, json.encode(create_req)) or {
		return err
	}

	json_res := json.decode(StatusResponse, res) or {
		return error('Failed to decode api response. Reason: ${err}')
	}

	if json_res.status == .error {
		error('Received an error status while creating DNS Record')
	}
}

pub fn (a Api) edit_record(record_type string, content string) ! {
	url := 'dns/editByNameType/${a.domain}/${record_type}'

	edit_req := EditRequest{
		a.api_key
		a.secret_api_key
		content
	}

	res := a.send_request(url, json.encode(edit_req)) or {
		return err
	}

	json_res := json.decode(StatusResponse, res) or {
		return error('Failed to decode api response. Reason: ${err}')
	}

	if json_res.status == .error {
		error('Received an error status while getting editing DNS Record')
	}
}
