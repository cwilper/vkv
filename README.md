# What is vkv?

`vkv` is a wrapper around `vault` that uses tab completion and simplified arguments to help you:

* Dump secrets as json
* Get values as plaintext
* Copy values to the clipboard
* Add and replace values in secrets
* Delete and purge secrets and values

...with any [HashiCorp Vault](https://www.vaultproject.io/)
[KV Engine](https://www.vaultproject.io/docs/secrets/kv/index.html) (versions 1 and 2).

## Usage

```
vkv path/to/secret                    # gets all key-value pairs of a secret as json
vkv path/to/secret -d                 # deletes a secret
vkv path/to/secret -p                 # purges a secret
vkv path/to/secret some_key           # prints the value of an existing key in a secret
vkv path/to/secret some_key .         # copies the value to the system clipboard
vkv path/to/secret some_key=-d        # deletes the value
vkv path/to/secret some_key=some-val  # sets the value (newlines via \n ok)
vkv path/to/secret some_key=-         # sets the value from stdin (actual newlines ok)
```

Hitting `TAB` while entering a path or key name will provide autocompletion based on existing data.

## Installation

* Make sure [vault](https://www.vaultproject.io/downloads.html)
  and [jq](https://stedolan.github.io/jq/) are installed and in your `PATH`.
* Source the `vkv.sh` script from your `.bashrc` or other startup script, e.g. `. $HOME/bin/vkv.sh`

## Configuration

### Path prefix: `VKV_PREFIX`

`vkv` paths are relative to a configured prefix, set by setting the `VKV_PREFIX` environment variable.
If this is not set, the default will be `secret`, which is the name of the default `kv` engine
configured with `vault` out of box.

### Clipboard program: `VKV_CLIPBOARD`

The clipboard functionality relies on an external program, set by setting the `VKV_CLIPBOARD` environment
variable. If this is not set, the default will be `pbcopy`, which is the tool that works for macOS.
If you're running another OS, look into `xsel` or `xclip`.

### Debugging: `VKV_DEBUG` and `VKV_TRACE`

If set (to any value, like `1`), this will activate verbose output so you can debug if something
is going wrong. `VKV_DEBUG` will cause `vkv` to print extra diagnostic information for each command,
while `VKV_TRACE` will cause it print all commands (and output) for every command it runs.
