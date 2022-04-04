# OS-Learning-Example


Beginner dev OS learning project in C.
Following ["Nanobyte"](https://github.com/chibicitiberiu/nanobyte_os) tutorial.

My intentions with this project is learning everything related to developing an operational system,
from the low level language such as assembly, to the build with make, and much more between, e.g how the computer handles memory and how the CPU work.

## Building

For Windows install [Ubuntu on WSL](https://ubuntu.com/wsl).

Install dependecies:
```
# Ubuntu:
$ sudo apt install make nasm qemu-system-x86
```
Run `make` to generate the img file. 
<br> <br> 
Run `qemu-system-i386 -fda build/main_floppy.img` to open qemu with this OS. 
