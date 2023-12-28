# SpiderOak ONE backup in a Container

This repository contains the specification of a docker file to run the
[SpiderOak ONE](https://spideroak.com/personal/spideroak-one) backup
software from inside a container.

The instructions in this file assume that you have an SpiderOak account
for personal backups already set up.

## Overview

The docker image contains the SpiderOak ONE client, and uses volume
mounts to obtain the credentials and store persistent configuration
and state data.

The username and credentials are mounted as individual files inside
the `/docker/secrets` directory in the container (similar to using
docker `secrets` but without requiring a docker swarm setup).
Similarly, the device name is mounted as an individual file inside
the `/docker/configs` directory in the container (similar to using
docker `configs` but, again, without requiring docker swarm).
Both credentials and device name are read-only inside the container.

The `/docker/configs` directory may also contain a file with anacron
configuration parameters. The anacron configuration is useful when
the SpiderOak ONE client is not able to receive change notifications
from the host file system. In that case, anacron can be used to
re-start the SpiderOak ONE client and force a full scan of the
directories to back up.

The writable persistent configuration and state for SpiderOak ONE is
mapped into the `/STATE` directory inside the container, and it should
be mapped to a persistent volume or host directory in the host.

On execution, the directories to backup are mounted read-only inside
the container. The Dockerfile defines a `/BACKUP` directory for
convenience (to mount any directory to back-up in there and avoid
path name conflicts), but it is not compulsory to use it.

On first start, the container registers the new device into the
SpiderOak account (note that **re-installing an existing device is not
supported**). Then, it starts backing up the selected files and
directories.

Note that the user and group of the container need to have read access
to the files and directories to back-up from the host. The Dockerfile
specifies a default user id and group id, that can be overridden to
your needs. (**CAVEAT**: if you run the container with different user and
group identifiers in the same host, you will need to register a
different device and use separate persistent configuration volumes;
otherwise, you risk messing up your set-up.)

This repository contains a `docker-compose.yaml` file to facilitate
management. Of course, you can run it using docker commands directly,
if you are familiar with them.

## Preparation

Before starting, you need to prepare some files with the basic configuration.
You will need four directories to store the read-only configuration, the
secrets, the preferences, and the writable persistent configuration and state.

Let's assume we will have them inside a directory called `spider` in our
home. We can create them with the following commands:

```bash
mkdir "$HOME/spider"
mkdir "$HOME/spider/configs"
mkdir "$HOME/spider/secrets"
mkdir "$HOME/spider/preferences"
mkdir "$HOME/spider/state"
```

Now you need to create the files for the credentials and the device name.
Beware that credentials are obfuscated with base64 encoding, but having
that stored in your filesystem can be a security risk. If you feel
uncomfortable with that, you can skip the creation of any of the user,
password and device files and define the following environment variables
when running the container (note that you still need the directories though,
even if they are empty):

* _SPIDEROAK_USER_: the username or mail of your SpiderOak account.
* _SPIDEROAK_PASSWORD_: the password of your SpiderOak account.
* _SPIDEROAK_DEVICE_: the name of the new device to register in your
  SpiderOak account.

If you choose to use the files instead of the environment variables, you
can create them with the following commands.

For the credentials, you can use:

```bash
echo -n 'YOUR_SPIDEROAK_USER' | base64 > ${HOME}/spider/secrets/spideroak_user.conf
echo -n 'YOUR_SPIDEROAK_PASSWORD' | base64 > ${HOME}/spider/secrets/spideroak_password.conf
```

For the device name, you can create the file using:

```bash
echo -n 'YOUR_DEVICE_NAME' > ${HOME}/spider/configs/spideroak_device.conf
```

Note that you cannot set the preferences using environment variables, but
you can just omit the creation of the `Preferences` file if you want to use
the defaults (see next section for the contents of `Preferences`).

Last but not least, you need to know which user and group to use to run the
container. The chosen user needs to have at least read/traverse permission
for the files and directories you want to back up. If you are using the
container to upload personal files, you may want to use your own user id
(otherwise, you need to find the uid and gid of the system user with backup
permissions).

The build specification has a default value of `1001` for user and group. You
can change that at build time, or override it at runtime by setting the
environment variables `SPIDEROAK_UID` and `SPIDEROAK_GID` (_WARNING_: do not
change the uid and gid after setup).

You can obtain your user's uid and gid with the following commands:

```bash
id -u
id -g
```

### Anacron configuration

In case the SpiderOak ONE is not able to receive change notifications from
the host file system (e.g. some container engines/configurations do not
work properly with i-notify), you may use the anacron set-up to run the
SpiderOak ONE client in batch mode and re-start it again at regular
intervals, forcing a full re-scan of the directories to back-up.

In order to do that, you need to create a file named
`spideroak_anacron.conf` with the following environment variables defined:

* _SPIDEROAK_ANACRON_: set the value to `true` if you want to run in
  anacron mode.
* _SPIDEROAK_ANACRON_START_HOURS_RANGE_: if defined, indicate at which
  hours during the day is the client allowed to start (e.g. "19-23").
* _SPIDEROAK_ANACRON_PERIOD_: The period in days between consecutive
  scans (defaults to 1).
* _SPIDEROAK_ANACRON_DELAY_: The minimum delay in minutes after the last
  execution (defaults to 60).
* _SPIDEROAK_ANACRON_RANDOM_DELAY_: the maximum number of minutes that the
  start of the process can be delayed, beyond the fixed delay (defaults to 5).

For example:

```
SPIDEROAK_ANACRON=true
SPIDEROAK_ANACRON_START_HOURS_RANGE=1-6
SPIDEROAK_ANACRON_PERIOD=3
SPIDEROAK_ANACRON_DELAY=30
SPIDEROAK_ANACRON_RANDOM_DELAY=5
```

Note that this file should be in the configurations directory (the same
where your `spideroak_device.conf` file is).

## Preferences

The SpiderOak ONE application allows you to set certain preferences via the
GUI, which is not very convenient for a headless execution in a container.
Nevertheless, though officially unsupported, it is also possible to set
them via a JSON file named `/etc/SpiderOakONE/Preferences`. The documentation
on how to handle this file can be found in the following link:

* [Advanced Application Management in SpiderOak Groups and Enterprise](https://spideroak.support/hc/en-us/articles/115001893023)

While reading that text, you will have to change every instance of
`SpiderOak Groups` (with a space) to `SpiderOakONE` (without a space).

The preferences file could look like the following:

```json
{
  "Wildcards": "Wildcards to match against files to not back up (e.g.: *.bck, *.tmp)",
  "FolderWildcards": "Wildcards for folders to not back up (e.g.: Windows)",
  "LimitBandwidthEnabled": true|false,
  "LimitUploadBucket": "Maximum upload in kilobytes per second (e.g: 75)",
  "FullScheduleEnable": false,
  "FullScanInterval": "Set the backup scan interval (e.g.: Automatic)",
  "EnableAutomaticScan": true
}
```

The content above, changing the description of the values into actual values,
needs to be placed in a file named `Preferences` inside the host directory
created to keep them (see previous section).

Additionally, it is possible to create a `BackupSet` file in the same directory
with the selection of files and directories to backup. For example:

```json
{
  "atleast": {
    "selected": [
      "/first/path/to/backup",
      "/second/path/to/backup"
    ]
  }
}
```

## Environment file

For convenience, it is useful to create an environment file in the same
directory as your `docker-compose.yaml` file. This will make unnecessary
to explicitly define the needed environment variables in the command line.
The default name for environment file is `.env`. The variables that you
may want to set up are:

* _SPIDEROAK_UID_: The user uid that the container should use to run.
  Optional, defaults to `1001`.
* _SPIDEROAK_GID_: The user group gid that the container should use to run.
  Optional, defaults to `1001`.
* _SPIDEROAK_USER_: The user name used inside the container, defaults to `spider`.
* _SPIDEROAK_GROUP_: The group name used inside the container, defaults to `spider`.
* _ACCOUNT_CONFIGDIR_: The host directory that contains the
  `spideroak_device.conf` file with the device name. Compulsory, even if
  empty.
* _ACCOUNT_SECRETDIR_: The host directory that contains the
  `spideroak_user.conf` and `spideroak_password.conf` files with the
  SpiderOak credentials in base64-encoding. Compulsory, even if
  empty.
* _BACKUP_PREFERENCES_: The host directory that may contain the `Preferences`
  file with the SpiderOak ONE preferences. Note that the file may not
  exist, but the directory is compulsory, even if empty.
* _BACKUP_STATEDIR_: The host directory to store the SpiderOak persistent
  configuration and state. Compulsory, must be writable by the container
  user.

The following is an example of an environment file (please adjust the values
to your own setup). Note the braces (`{`, `}`) around the environment
variables.

```
ACCOUNT_CONFIGDIR="${HOME}/spider/configs"
ACCOUNT_SECRETDIR="${HOME}/spider/secrets"
BACKUP_PREFERENCES="${HOME}/spider/preferences"
BACKUP_STATEDIR="${HOME}/spider/state"
SPIDEROAK_UID="1001"
SPIDEROAK_GID="1001"
```

## Building

Assuming you have the `.env` file ready as indicated in the previous section,
you can build the image by going to the directory containing the
`docker-compose.yaml` file and issuing the following command:

```bash
docker-compose build
```

You can tweak the following build arguments in the `docker-compose.yaml` file:

* _BASE_IMAGE_VERSION_: The Alpine version to use as a base image.
* _SPIDEROAK_VERSION_: The SpiderOak ONE version from the distributed tar
  (`.tgz`) file.
* _SPIDEROAK_UID_: The default user id to use when running the container.
* _SPIDEROAK_GID_: The default user group id to use when running the container.

The following values are also available as build arguments, but changing them
is discouraged unless you know what you are doing:

* _SPIDEROAK_USER_: The user name for the SpiderOak user inside the container.
  This is used only to have a 'home' directory inside the container where the
  SpiderOak ONE will search for configuration. The actual mapping with host
  users is done via user uid and gid.
* _SPIDEROAK_HOME_: The home directory inside the container.
* _SPIDEROAK_STATEDIR_: The internal container directory where the external
  volume for persistent configuration and state is mapped.
* _SPIDEROAK_BACKUPDIR_: The directory created to hold the host mounts
  containing the data to back up.

## Setup

Once the image is build and all the configuration files and environment
variables are set up as indicated in the previous sections, you can start
the `spider_one` service. Before doing that, you need to set up the
configuration. You can do it with the following command:

```bash
docker-compose run --rm one /app/setup
```

Note that the command above may take a loooong time (expect several minutes or
hours, if you have several devices already registered), while it synchronizes
with your SpiderOak account. The service will end once the work is done
(interrupting it is not recommended).

## Checking status

You can validate that the set-up finished correctly and check your account
information running the following command:

```bash
docker-compose run --rm one /app/info
```

Note that the command will not work properly if the SpiderOak service is
already running.

## Selecting directories to back up

To select the directories to back up, you need two steps. The first one
is mounting the directories into the container. To do so, you need to
update the service `volume` section in the `docker-compose.yaml` file.
The default file has two examples for the host `/etc` and `/usr/local/bin`
directories; you may want to remove those and replace them with the
actual host directories containing files that you want to back up.

Remember that the host directories you mount should be readable by the
container uid and gid.

The snippets you should add for every host directory you want to mount
should look like the following (mind the indentation and the dashes `-`):

```yaml
      - type: bind
        source: "/absolute/path/in/the/host"
        target: "/BACKUP/path/in/the/container"
        read_only: true
        bind:
          propagation: "rslave"
```

The `source` should contain the absolute path of the host directory you
want to mount; the `target` is the directory in the container where it
will be mounted (note that you will have to use `target` as a base path
when you indicate SpiderOak ONE the actual files and directories to
back up); the `rslave` propagation mode makes recursively mounted file
systems to be visible from the container, and the `read_only` flag
prevents accidental writings to the data you want to back up.
Note that you should repeat the above for each host directory you want
to mount.

Once you have configured the mount points from your host, you need to
actually tell SpiderOak ONE that you want to back up files and
directories in them. 

_NOTE_: the following instructions assume you have already executed the
Setup step.

With the service down, you can execute the following command to see which
is the current backup selection:

```bash
docker-compose run --rm one /app/select
```

You can use the same command with arguments to include and exclude files
and directories. The format of the argument consists of a prefix,
followed by a colon (`:`) and the path of the file or directory inside
the container. The valid prefixes are:

* _Dir_: Select the specified directory for backup.
* _File_: Select the specified file for backup.
* _ExcludeDir_: Exclude the specified directory from backup.
* _ExcludeFile_: Exclude the specified file from backup.

For example, with the default configuration, to include the mounted host
`/etc/systemd` directory but exclude the `system` subdirectory, you could
execute the following command:

```bash
docker-compose run --rm one /app/select Dir:/BACKUP/etc/systemd ExcludeDir:/BACKUP/etc/systemd/system
```

You can execute commands like the above any time you want to add a new
inclusion or exclusion. For example, to add the host mounted `/etc/rc.local`
file, you can execute the following command:

```bash
docker-compose run --rm one /app/select File:/BACKUP/etc/rc.local
```

You can reset your selections with the following command:

```bash
docker-compose run --rm one /app/select --reset
```

## Running the service

Once the account is set up and the selection done, you can start the service
from the directory with the `docker-compose.yaml` file using the following
command:

```bash
docker-compose up --detach
```

And you can stop the service with:

```bash
docker-compose down
```

While the service is running, you can execute arbitrary commands on the
container using the `docker-compose exec` command. For example, to verify
which file systems are mounted, you can run:

```bash
docker-compose exec one mount
```

## Running arbitrary SpiderOak ONE commands

In case of need, you can run the SpiderOakONE command with the same
environment settings as the service. Make sure that the service is down,
since SpiderOak usually does not support multiple application instances,
and running several commands at the same time may mess up the state.

```bash
docker-compose run --rm one -c "SpiderOakONE --help"
```

## Running on Synology

One of the purposes of the spider container is to run it directly
inside a NAS Station like Synology's
[DS Plus Series](https://www.synology.com/products?product_line=ds_plus).
However, some additional tweaks are required. The following instructions
may vary depending on the brand, model and version of your NAS system.

Assuming you are logged into your Synology NAS via web as an administrator
user, you need to go to the `Package Center` and make sure the `Docker`
package is installed. This will automatically create a shared folder called
`docker` and install the `docker` and `docker-compose` commands in the system.

In the `Control Panel`, go to the `User & Group` tab and create a group for
backup application purposes (e.g. `backup`). Give this group read-only
permissions on the shared folders you want to back up (via `Edit/Permissions`
button).

Now, create a user to run the spider container (e.g. `spider`). Assign this
newly created user to the group `backup`.

Once the user and group are created, upload the contents of this repository
to your Synology NAS system using an administrator user. If ssh is enabled,
you can upload the contents via `sftp`. I recommend to create a folder inside
the `docker` shared folder (e.g. `/path/to/docker_folder/spider`).

Once uploaded, connect to your Synology NAS system via ssh using an
administrator user. There, you need to create the folders for config, secrets
and state. I recommend creating a folder inside the `docker` shared folder
called `_volumes` for this purpose. For example:

```bash
mkdir /path/to/docker_folder/_volumes/spider/configs
mkdir /path/to/docker_folder/_volumes/spider/secrets
mkdir /path/to/docker_folder/_volumes/spider/preferences
mkdir /path/to/docker_folder/_volumes/spider/state
chgrp backup /path/to/docker_folder/_volumes/spider/state
chmod -R g+w /path/to/docker_folder/_volumes/spider/state
```

Notice that we need to change the group and permissions of the persistent
state directory, since it must be writable by the container user.

Also, create and populate the `spideroak_user.conf`, `spideroak_password.conf`
and `spideroak_device.conf` files as instructed in the previous sections,
or be ready to set the corresponding environment variables when invoking
the `docker-compose` commands.

Get the uid and gid of the `spider` user and `backup` group, as you will
need them later:

```bash
id -u spider
```

```bash
grep '^backup:' /etc/group | cut -d : -f 3
```

Now edit your `docker-compose.yaml` file to adjust the settings and add the
volume mappings for the shared folders you want to backup. Also adjust
the `SPIDEROAK_UID` and `SPIDEROAK_GID` settings.

Finally, create your `.env` file for the environment variables. It should
look similar to the following:

```
ACCOUNT_CONFIGDIR="/path/to/docker_folder/_volumes/spider/configs"
ACCOUNT_SECRETDIR="/path/to/docker_folder/_volumes/spider/secrets"
BACKUP_PREFERENCES="/path/to/docker_folder/_volumes/spider/state"
BACKUP_STATEDIR="/path/to/docker_folder/_volumes/spider/state"
SPIDEROAK_UID="spider_user_uid"
SPIDEROAK_GID="backup_group_gid"
```

The following is a possible configuration for the `Preferences` file
(please adapt it to your needs):

```json
{
  "FolderWildcards": "@eaDir, @tmp, .DS_Store",
  "LimitBandwidthEnabled": true,
  "LimitUploadBucket": "75",
  "FullScanInterval": "Automatic",
  "FullScheduleEnable": true,
  "FullScheduleDay": "Monday",
  "FullScheduleHour": "10",
  "FullScheduleAMPM": "PM",
  "SyncScheduleEnable": false,
  "ShareScheduleEnable": false,
  "EnableAutomaticScan": true
}
```

Now you are ready to build, setup and start the system. The Synology NAS
system may restrict docker handling to the `root` user (not any administrator).
So you may have to become `root` by issuing the following command and
entering your administrator user password when requested:

```bash
sudo -i
```

As `root`, navigate to the folder where the `docker-compose.yaml` and `.env`
files reside, and build the image with:

```bash
docker-compose build
```

Once the image is build, you should be able to see it via the `docker`
plugin, in the `Image` tab. You can set up the device, configure your
selections and start the services (using the `root` user) as instructed
in the initial sections of this guide.

While the container is running, you should be able to check its status
via the `docker` plugin, by clicking in the `Details` option in the
`Container` tab.

In some cases, you may find the following error when trying to start the
container (path and mount point may be different):

```
Error response from daemon: path /volume1 is mounted on /BACKUP/volume1 but it is not a shared or slave mount
```

This problem can be solved by executing the following commands from your root
account in synology:

```bash
mount --make-shared /volume1/
systemctl daemon-reload
```

In order to make it persistent across reboots, you may create a task executing
the above script every time the synology boots. In order to do so, you may
follow the next steps:

1. Open the control panel.
2. Go the `Task Scheduler` tab.
3. Create a `Triggered Task` with a `User-defined script`.
4. Set the name for the Task (e.g. `Mount --make-shared`).
5. Set the trigger `Event` to `Boot-up`.
6. Set the user to `root`.
7. In `Task Settings` copy & paste the mount and systemctl commands from above as `User-defined script`.
8. Click on the `Ok` button to save the task.
