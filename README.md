# vega-headless

Build Fire TV Vega OS apps and run them in the **Vega Virtual Device on a headless Linux server**, in Docker. No Mac, no Fire TV, no desktop session. Useful for CI, for laptops without 20 GB of free disk, and for teams on Intel Macs, where SDK 0.24 is the last supported version.

The image wraps the official Vega SDK and fixes the problems we hit running it headless:

| Problem | What happens | Fix in this image |
| --- | --- | --- |
| Installer refuses root | "This script must not be run as root" | SDK installed as a regular `dev` user with sudo |
| Installer needs jq | not in the documented prerequisites | jq preinstalled |
| Installer prompts read stdin | piped installs fail with EOF | installer runs from a file with default answers |
| `build-kepler` hangs without a TTY | no output for 10+ minutes | `vega-build` runs with `CI=true` and stdin closed |
| Device needs IPv6 | boot fails after 600 s with "failed to access shell" | run with IPv6 enabled (see below) |
| `--no-gl-accel` renders nothing | every screenshot is black | Mesa software OpenGL under Xvfb with GLX |
| Zombie emulators lock the AVD | "Running multiple emulators with the same AVD" | run with `--init`; `vvd-start` clears old instances |
| `run-app` cannot find the app | "App could not be determined" | `vvd-run` uses `install-app` and `launch-app` |

## Requirements

* Linux x86_64 host with KVM (`ls /dev/kvm`)
* Docker
* About 15 GB of disk for the image

## Quick start

```bash
docker build -t vega-headless .

# The virtual device binds to ::1 with address checks that need an IPv6 address on the container.
docker network create --ipv6 --subnet fd00:5e9a::/64 vega-v6

docker run -it --rm --init \
  --device /dev/kvm \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --network vega-v6 \
  -v "$PWD":/workspace -w /workspace \
  vega-headless bash
```

Inside the container:

```bash
vvd-start                                   # boot the Vega Virtual Device (about 10 s with KVM)
vega-build apps/vega                        # build your app, prints the .vpkg files
vvd-run apps/vega/build/x86_64-release/*.vpkg com.example.app.main
vvd-keys Down Right Return sleep:3          # press remote keys
vvd-shot                                    # 1920x1080 screenshot, prints the file path
vvd-record 20 /workspace/run.webm           # 1080p, 24 fps, with sound
```

Remote keys for `vvd-keys`: `Up`, `Down`, `Left`, `Right`, `Return` (select), `Escape` (back), `F1` (home), `F4` (play and pause). `type:hello` types text into a focused text field.

## Notes

* Media URLs must be https. With plain http the W3C media player fails with `MPB Call failed with code: 50004` even though `fetch` and images work.
* `vvd-shot` and `vvd-record` use the emulator console, so they are full resolution. Recording with `ffmpeg -f x11grab` on the Xvfb display stalls for seconds at a time while the device draws; the console's `screenrecord` gives smooth 1080p VP9 at 24 fps with the device's sound. It only writes frames when the screen changes, so the file has a variable frame rate.
* Without a GPU the device draws with Mesa in software. Interfaces run fine, but video plays at about half speed and around 11 frames per second, so judge playback smoothness on a real Fire TV.
* After several hours the device can stop reacting to keys while the app stays on screen. Restart it with `vvd-start` and reinstall the app.
* The image installs the latest SDK at build time. Pin a version inside the container with `vega sdk install <version>` and `vega sdk use <version>`.

Built while making [StoryQuest](https://github.com/) for the Amazon Developer hackathon "Build, Ship, Shape". The Vega SDK itself is Amazon's and is downloaded from Amazon at build time; this repository only contains the Dockerfile and scripts.

## License

MIT
