#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    char *env = getenv("admin");
    if (env != NULL) {
        setuid(0);
        setgid(0);
        system("/bin/bash");
    } else {
        puts("Not an Admin");
    }
    return 0;
}
