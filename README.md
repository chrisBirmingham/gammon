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

You can manually invoke gammon like so:

```commandline
gammon -c ./path/to/config/file.json -l ./path/to/log/file.log
```

Gammon will first retrieve your public IP address via calling Porkbuns ping address, then it retrieves the A record for your domain. If one doesn't exist it will try to create it, otherwise it will check the stored IP address with the one it got from the ping request. If they don't match, your public IP address has changed and it will update the record.

You can also skip the IP address check and force an IP address for your domain using the `--ip` option.

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

## Cron usage

To invoke gammon via cron, add this to your crontab:

```crontab
*/10 * * * * /usr/local/bin/gammon -c ./path/to/config/file.json -l /path/to/log/file.log
```

This will run gammon every 10 minutes.

## Cavets

* Only supports IPv4 IP addresses
* Doesn't support mulitiple DNS A records.
* Only supports one domain but can be invoked with different config files for different domains.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chrisBirmingham/gammon.
