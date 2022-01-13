mkfs: mkfs.c
	gcc -Werror -Wall mkfs.c -o mkfs

fs.img: mkfs
	./mkfs fs.img $(shell cat src/userfile.txt)
	mv fs.img src/
	rm mkfs