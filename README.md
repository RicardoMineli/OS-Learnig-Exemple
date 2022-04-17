# OS-Learning-Example


Beginner dev OS learning project in C.
Following ["Nanobyte"](https://github.com/chibicitiberiu/nanobyte_os) tutorial.

Learning all kinds of stuff in the operating system world!

## Building

For Windows install [Ubuntu on WSL](https://docs.microsoft.com/en-us/windows/wsl/install).

Install dependecies:
```
# Ubuntu:
$ sudo apt install make nasm mtools qemu-system-x86
```
Run `make` to generate the img file. 
<br> <br> 
Run `qemu-system-i386 -fda build/main_floppy.img` to open qemu with this OS.
<br> <br> 
Or run `./run.sh`
