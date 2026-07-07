
At the very beginning, do `git submodule update --init`, then:

```
$ cd seL4
$ git checkout 14.0.0
$ cd ../

$ python3.12 -m venv pyenv
$ . ./pyenv/bin/activate
$ cd microkit
$ ../pyenv/bin/pip install --upgrade pip setuptools wheel
$ ../pyenv/bin/pip install -r ./requirements.txt
$ ../pyenv/bin/python ./build_sdk.py --sel4=../seL4 --boards=qemu_virt_aarch64
$ cd ..

$ cd sdfgen
$ ../pyenv/bin/pip install .
$ cd ..`

$ export MICROKIT_SDK=$PWD/microkit/release/microkit-sdk-2.1.0-dev

$ cd lionsos
$ git submodule update --init
$ cd examples/proto-container
$ make qemu
```

At this stage, you should be able to see the red output from the shell of the `protocon` demo.

You can try the following shell commands:

```
$ start client_echo.elf
$ lspcs
$ start client_echo.elf
$ start client_echo.elf
$ start client_echo.elf
```

You should be able to see some intertwined serial colours showing different clients
are talking to each other via the monitor PD. The `lspcs` command prints out the system
state, which includes the number of available PDs and their current life cycle states.

It is also worthwhile to try

```
$ hang -i 0
$ hang -i 1
$ resume -i 0
$ resume -i 1
```

You should be able to see some PD are hang once you type in the `hang` command,
which follows by the ID of a dynamic PD that you retrieved from the `lspcs` command.
With the `resume` command, you should be able to resume a PD which is currently hanging.

There are also other commands (e.g., `stop -i x`), you can try it out yourselves or
modify the `frontend` PD (i.e., the shell) to implement the mechanisms you want.