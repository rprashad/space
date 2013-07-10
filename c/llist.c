#include <stdio.h>


typedef struct node {

	struct node *next;
	int val;
}Node;

void traverse(Node *n);
void init(Node **n, int val);
void add(Node *n, int val);

int main (int argc, char **argv) {

	Node *n;
	init(&n, 99);
	add(n,1);
	add(n,2);
	add(n,69);
	traverse(n);

}

void traverse(Node *n) {

	while (n != NULL) {
		printf("VAL: %i\n", n->val);
		n = n->next;
	}
}

void add(Node *n, int val) {

	while(n->next != NULL) {
		n = n->next;
	}
	Node *p = (Node *)malloc(sizeof(Node));
	p->val = val;
	p->next = NULL;
	n->next = p;
}

void init(Node **n, int val) {
	*n = (Node *) malloc(sizeof(Node));
	if (n != NULL) {
		(*n)->val = val;
		(*n)->next = NULL;
	}
	else {
		printf("Could not initialize list!\n");
	}
}
