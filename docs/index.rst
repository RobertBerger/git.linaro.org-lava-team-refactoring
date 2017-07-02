Dispatcher refactoring tests
############################

.. warning:: The new code is still developing, some areas are absent,
             some areas will change substantially before it will work.
             All details here need to be seen only as examples and the
             specific code may well change independently.

The test jobs described in these files may stop functioning at any
time - this is **not** a bug. The reference jobs for the refactoring
are those supporting the unit tests. If the unit tests pass and these
files fail, the error is in these files.

Notable changes
***************

* **device_types**: redundant. All device type information is handled
  via the master scheduler, the admin database interface and templates.
  The refactoring results in the dispatcher only seeing a single YAML
  file describing everything about the device. This can easily look like
  unnecessary duplication in these files but **the device files here are
  temporary copies of generated data**.
* **Locations**: The dispatcher expects device configuration files to
  exist in a ``./devices`` directory. Start ``lava-dispatch`` from a
  directory where the correct device YAML file exists in a ``./devices/``
  directory.
* **output-dir**: Mandatory for several devices. This needs better error
  handling in the codebase but, in general, it is **always** necessary
  to specify an output directory where the log files will be written.
* **logs**: Scripts in the ``scripts/cron`` directory will generate
  logs in that directory and new directories should be added to the
  ``.gitignore`` file.
* **Adding devices**: Combine the existing device type configuration
  into a similar structure as the other **device** YAML files, changing
  the syntax to YAML.
* **Syntax**: **Always** check your YAML syntax:

  http://yaml-online-parser.appspot.com/?yaml=&type=json
