# Gammon

A dynamic DNS client for updating Porkbun DNS records.

## Installation

```commandline
git clone https://github.com/chrisBirmingham/gammon
cd gammon
make
sudo make install
```

## Usage

Run `gammon` to invoke the command. By default gammon will try to read the `/etc/gammon.json` config file, otherwise you can use the `-f` option to specify your own config file.

The config file follows this format:

```json
{
	"domain": "foo.bar",
	"api_key": "foo",
	"secret_api_key": "bar"
}
```

## Cron usage

Gammon can be invoked via cron. Run:

```commandline
crontab -e
```

And add this to your crontab

```crontab
*/10 * * * * /usr/local/bin/gammon >> /var/log/gammon.log
```

This will run gammon every 10 minutes and log it's output to a log file.
