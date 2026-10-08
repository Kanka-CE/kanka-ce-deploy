# Kanka CE — Self-Hosting Stack

[Kanka](https://github.com/owlchester/kanka) is a worldbuilding and RPG campaign management tool. 
[Kanka-CE](https://github.com/kinnewig/kanka-community-edition) is the community-maintained fork for easy self-hosting.

**This is the repo you want if you just want to run Kanka CE.** 
It contains everything needed to deploy it via Docker Compose, plus the patch set used to build it.

## What's in here

- **Patches** applied to upstream Kanka to produce the source published in [kanka-community-edition](https://github.com/Kanka-CE/kanka-community-edition).
- **`docker-compose.yml`** and **`.env.example`** to run the prebuilt Kanka CE image.
- The automation (`build-container.sh`, CI workflows) that keeps Kanka CE in sync with new upstream Kanka releases.

This repo does **not** contain the modified Kanka source itself, and does **not** build the container image — see the table at the bottom for where those live.


## Quick Start Guide

Self-hosting instructions are also available in the [Wiki](https://github.com/Kanka-CE/kanka-community-edition/wiki/Self%E2%80%90Hosting-Guide).

If you want to use Quadlets/Podman instead of Docker, see [kanka-ce-deploy-quadlets](https://github.com/Kanka-CE/kanka-ce-deploy-quadlets)

### Preparation
This guide assumes your server is already up and running, with a recent and
updated version of a server-suitable Linux distribution, e.g., [Rocky Linux](https://rockylinux.org/),
[Debian](https://www.debian.org/index.de.html), etc. You also need either
[Docker](https://docs.docker.com/engine/install/) and docker-compose, or, if you're
using [Podman](https://podman.io/docs/installation), Podman and podman-compose.

<details>
<summary>Docker – Debian (apt)</summary>

```bash
sudo apt -y install docker docker-compose
```

</details>

<details>
<summary>Podman – Debian (apt)</summary>

```bash
sudo apt -y install podman podman-compose
```

</details>

<details>
<summary>Docker – Rocky Linux (dnf)</summary>

For more details, see [the official documentation](https://docs.rockylinux.org/10/gemstones/containers/docker/).

Add the Docker repository:

```bash
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
```

Install Docker, Docker Compose, and other useful plugins:

```bash
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Start and enable Docker:

```bash
sudo systemctl --now enable docker
```

</details>

<details>
<summary>Podman – Rocky Linux (dnf)</summary>

Enable EPEL repositories:

```bash
sudo dnf config-manager --set-enabled crb
sudo dnf install epel-release
```

Install Podman and Podman Compose:

```bash
sudo dnf -y install podman podman-compose
```

</details>

### Running Kanka-CE
- Download the `docker-compose`, `.env.example`, and `gen-passwords.sh`, this can be done simply via:
```bash
git clone https://github.com/Kanka-CE/kanka-ce-deploy.git
```

- Enter the new folder and create a `.env` file by copying and adjusting `.env.example`:
```bash
cp .env.example .env
```

- Set strong passwords in the security section of the `.env` file:
```bash
./gen-passwords.sh
```

- Create the persistent folder
```bash
source .env
mkdir -p ${KANKA_CE_DATA}/{kanka,mariadb,meilisearch}

# Adjust the permissions (replace the User-ID with the user ID used by Docker, e.g., 999, ...)
chown -R 1000:1000 ${KANKA_CE_DATA}
```

- Run Kanka-CE
```bash
docker compose up -d
```

### Post-installation
You can access the web UI at <http://localhost:80> (or a different port if you edited the `.env` file). 
It's strongly recommended to set up a reverse proxy. 
Here's an nginx config to start from — replace `{your-domain}.com` and `{ip-of-your-kanka-ce-host}`:

<details>
<summary>Example nginx configuration</summary>

```nginx
server {
    listen 80;
    server_name kanka.{your-domain}.com;

    # Redirect all HTTP requests to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name kanka.{your-domain}.com;

    # To only allow local traffic, uncomment the following two lines:
    #allow  192.168.1.0/24;
    #deny   all;

    # Restrict the maximal upload size, 0 means no restriction.
    client_max_body_size 0;

    add_header Strict-Transport-Security "max-age=15552000; includeSubDomains; preload;" always;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/{your-domain}.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{your-domain}.com/privkey.pem;

    # Reverse proxy to Kanka CE
    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://{ip-of-your-kanka-ce-host}:8081;
        proxy_redirect off;
    }
}
```

</details>

### Enable Premium for your world!
Premium isn't enabled by default (yet), so you need to enable it by hand for each world.


## Contributing
Kanka Community Edition and Kanka CE Tools can only exist if the community helps build them.
To get started, you can read the [CONTRIBUTING.md](https://github.com/Kanka-CE/kanka-ce-container/blob/main/CONTRIBUTING.md). 
This project is entirely maintained by volunteers, people who love Kanka, want to self‑host it, and believe in open collaboration. Every improvement, every fix, every idea comes from people like you. Kanka CE is still in an early stage, so help is appreciated very much!

No contribution is too small, even a typo fix helps move the project forward.

If you want Kanka CE to grow, stay compatible, and remain self‑hostable,  
**please consider contributing. The Community Edition lives through its community.**


## Related repositories
| Repo | What it's for |
|---|---|
| [kanka-community-edition](https://github.com/Kanka-CE/kanka-community-edition) | The patched Kanka source these patches produce |
| [docker-kanka-ce](https://github.com/Kanka-CE/docker-kanka-ce) | The Dockerfile that builds the image this compose file runs |
| [kanka-ce-deploy-quadlets](https://github.com/Kanka-CE/kanka-ce-deploy-quadlets) | Quadlets to run KankaCE via Podman |


## License
This repository contains only scripts and resources, not Kanka itself.  
It is not affiliated with the official Kanka project.  
All patches apply to the upstream Kanka codebase, which is licensed under its own terms.

The scripts in this repository are released under the **LGPL 2.1** license.

If you enjoy using the Community Edition, please consider supporting the official Kanka project:


## ❤️ Support the Official Kanka Project
Kanka CE exists because the upstream project is amazing.
If you enjoy using Kanka or Kanka CE, please consider supporting the original creators:

💙 **Kanka Website:** https://kanka.io  

