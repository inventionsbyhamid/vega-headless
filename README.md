# vega-headless

Run Amazon's Vega SDK and the Vega Virtual Device (the Fire TV simulator) inside Docker on a Linux server with no screen. Build your Fire TV app, install it, press remote buttons, take screenshots and record video, all from the command line.

* No Mac and no Fire TV needed
* Works on a server or in CI
* Keeps the 20 GB SDK off your laptop
* Fixes the problems you hit when running the SDK this way (listed below)

## You need

* A Linux x86_64 machine with KVM. Check with `ls /dev/kvm`.
* Docker
* About 15 GB of free disk

## Install

```bash
git clone https://github.com/inventionsbyhamid/vega-headless.git
cd vega-headless
docker build -t vega-headless .

# The virtual device needs IPv6 inside the container.
docker network create --ipv6 --subnet fd00:5e9a::/64 vega-v6
```

## Use

Start a container with your app's folder mounted:

```bash
docker run -it --rm --init \
  --device /dev/kvm \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --network vega-v6 \
  -v "$PWD":/workspace -w /workspace \
  vega-headless bash
```

Then, inside the container:

| Command | What it does |
| --- | --- |
| `vvd-start` | Starts the virtual device (about 10 seconds) |
| `vega-build apps/vega` | Builds your app and prints the `.vpkg` files |
| `vvd-run <file.vpkg> <app id>` | Installs and opens your app |
| `vvd-keys Down Right Return sleep:3` | Presses remote buttons |
| `vvd-shot` | Saves a 1920x1080 screenshot and prints its path |
| `vvd-record 20 /workspace/run.webm` | Records 20 seconds of 1080p video with sound |

Example:

```bash
vvd-start
vega-build apps/vega
vvd-run apps/vega/build/x86_64-release/*.vpkg com.example.app.main
vvd-keys Right Return sleep:2
vvd-shot
```

Remote buttons for `vvd-keys`: `Up`, `Down`, `Left`, `Right`, `Return` (select), `Escape` (back), `F1` (home), `F4` (play and pause). `type:hello` types text into a text field. `sleep:2` waits two seconds.

## Problems it fixes

| Problem | Fix |
| --- | --- |
| The SDK installer refuses to run as root | Installs as a normal `dev` user |
| The installer needs `jq`, which the docs don't list | Comes installed |
| The installer fails when its questions come from a pipe | Runs from a file with the default answers |
| App builds hang with no output when there is no terminal | `vega-build` runs them in CI mode |
| The device fails to boot after 10 minutes without IPv6 | The `docker run` command above turns IPv6 on |
| Screenshots are black without a graphics card | Draws in software with Mesa on a virtual screen |
| A stuck old emulator blocks the new one | Run with `--init`; `vvd-start` clears old instances |
| `vega device run-app` can't find the app | `vvd-run` installs and launches by app id |

## Good to know

* Video must come from https addresses. Plain http fails in the player with error 50004, even though images and `fetch` work.
* Without a graphics card the device draws everything in software. Menus work, but video plays at about half speed and animations at about 10 frames a second. Check smoothness on a real Fire TV.
* `vvd-record` uses the emulator's own recorder, which is smooth at 24 frames a second. It skips frames when nothing changes and drops sound during silence. When you edit a recording with ffmpeg, add `-af aresample=async=1` to keep sound in sync.
* After many hours the device can stop reacting to buttons. Run `vvd-start` again and reinstall your app.
* The image installs the newest SDK when you build it. To pin a version, run `vega sdk install <version>` and `vega sdk use <version>` inside the container.

Made while building [StoryQuest](https://github.com/inventionsbyhamid/storyquest) for the Amazon Developer hackathon "Build, Ship, Shape". The Vega SDK belongs to Amazon and is downloaded from Amazon when you build the image. This repository only holds the Dockerfile and scripts.

## License

MIT, see [LICENSE](LICENSE).
