#include <stdio.h>
#include <stdlib.h>


typedef struct split_t {
	int count;
	char **context;
}split_t;

split_t *split(const char *dlim, char *c) {
	int len = strlen(c);
	char buff[1024];
	int j = 0;
	int k = 0;
	split_t *split = (split_t *)malloc(sizeof(split_t));
	if (split == NULL) {
		printf("failed to allocated mem for split_t!\n");
	}
	split->count = -1;
	//allocate pointer to pointer
	split->context = (char *) malloc(sizeof(char *) * 50);
	

	while (k < (len +1)) {
		if (*c == *dlim || k == len || *c == '\n') {
			split->count++;
			// printf("Count: %i String Size: %i\n", split->count, j);
			split->context[split->count] = malloc(sizeof(char) * (j + 1));	
			strncpy(split->context[split->count], buff, sizeof(char) * j);
			// printf("Got: %s\n",split->context[split->count]);
			j = 0;
		}	
		else {
			buff[j] = *c;
			j++;	
		}
		c++;
		k++;
	}
	return split;
}

int main (int argc, char **argv) {

	FILE *f = fopen("/etc/passwd", "r");
	char *line;
	size_t len = 0;
	ssize_t read;
	split_t *s;
	if (f == NULL) {
		printf("Could not open file!\n");
	}
           while ((read = getline(&line, &len, f)) != -1) {
               // printf("Retrieved line of length %zu :\n", read);
               printf("%s", line);
	       s = split(":", line);
	       int x = 0;
		for (x; x <= s->count; x++) {
			printf("Got: %s\n", s->context[x]);
		}
           }


}


