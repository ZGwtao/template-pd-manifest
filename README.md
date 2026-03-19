
At the very beginning, do `git submodule update --init`, then:

```
$ cd seL4
$ git checkout 14.0.0
$ cd ../

$ python3.12 -m venv pyenv
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
$ make
$ make qemu
```

At this stage, you should be able to see the red output from the shell of the `protocon` demo. However, this is yet from ready, we need to exit from the QEMU via `Ctrl a` then `x`, and try initialising the `qemu_disk` (i.e., persistent storage for the monitor, shell, and proto-containers)

`$ mkdir build/mbp`

These commands require sudo:

```
$ ./copy2ramdisk.sh build/trampoline.elf 1
$ ./copy2ramdisk.sh build/protocon.elf 1
$ ./copy2ramdisk.sh build/client.elf 1
```

The above commands fill out the partition for frontend.

```
$ ./copy2ramdisk.sh build/serial_client_protocon0.data 2
$ ./copy2ramdisk.sh build/serial_client_protocon1.data 2
$ ./copy2ramdisk.sh build/serial_client_protocon2.data 2
$ ./copy2ramdisk.sh build/serial_client_protocon3.data 2
```

The above commands fill out the partition for monitor
Now, run `make qemu` again, you should be able to see the logs as in **log1.txt**.

Try: `start client.elf`, and repeat, you can see the results as in **log2.txt**
