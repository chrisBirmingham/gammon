# Gammon

A dynamic DNS client for updating Porkbun DNS records.

## Installation

V doesn't seem to have support for installing dependencies specified in your v.mod yet so first you'll need to install the syslog lib from vpm.

```commandline
v install vseryakov.syslog
```

Then run:

```commandline
git clone https://github.com/chrisBirmingham/gammon
cd gammon
make
sudo make install
```

## Usage

Gammon can be directly invoked like so:

```commandline
gammon -c ./path/to/config/file.json
```

Gammon will first retrieve your public IP address via calling Porkbuns ping address, then it will retrieve the A record for your domain. If one doesn't exist it will try to create it, otherwise it will check the stored IP address with the one returned earlier. If they don't match it will update the DNS record.

You can also skip the IP address check and force a new IP address by using the `--ip` option.

## As a daemon

Running the provided makefile also creates a symlink to `gammon` called `gammond`. This provides a pseudo daemon like functionality for gammon. `gammond` doesn't accept the `--ip` option and will
poll porkbuns api every 10 minutes for changes in your public IP address. Logs are redirected to syslog.

For systemd users you can copy/use the provided service file to set up the daemon service. For non systemd users, I haven't tested yet but [BSD's Daemonize](https://man.freebsd.org/cgi/man.cgi?query=daemonize&sektion=1&manpath=FreeBSD+13.2-RELEASE+and+Ports) program seems to provide the same functionality for daemonising gammon.

### Configuration

The config file must follow this format:

```json
{
	"domain": "your domain.com",
	"api_key": "your porkbun api key",
	"secret_api_key": "your porkbun secret api key"
}
```

You can find/create your api key and secret key [here](https://kb.porkbun.com/article/190-getting-started-with-the-porkbun-api). Make sure the file is only readable by root or the user who runs gammon.

## Cavets

* No windows support
* Only supports IPv4 IP addresses
* Doesn't support mulitiple DNS A records.
* Only supports one domain but can be invoked with different config files for different domains.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chrisBirmingham/gammon.
