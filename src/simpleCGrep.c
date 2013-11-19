//
//  simpleCGrep.c
//  simpleCGrep
//
//  Created by HaoJi on 10/29/13.
//  Copyright (c) 2013 HaoJi. All rights reserved.
//

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define BUFSIZE 5000
#define FAILURE -1
#define SUCCESS 0

void match(char *buf, char *pattern)
{
    char *p, *q;
    for(p = buf, q = pattern; *p != '\0'; p++)
    {
        if(*p != *q)
            continue;
        else
        {
            for( ; *p == *q; p++, q++);
            if(*q == '\0')
            {
                printf("%s", buf);
                return;
            }
            q = pattern;
        }
    }
}

int main(int argc, char *argv[])
{
    char buf[BUFSIZE];
    char pattern[BUFSIZE];
    char file_name[BUFSIZE];
    FILE *fp;
    
    memset(pattern, 0, BUFSIZE);
    memset(buf, 0, BUFSIZE);
    memset(file_name, 0, BUFSIZE);
    
    strcpy(pattern, argv[1]);
    strcpy(file_name, argv[2]);

    fp=(FILE *)fopen(file_name, "r");
    if(fp==NULL)
    {
        perror("fopen():");
        return FAILURE;
    }
    
    while(fgets(buf, BUFSIZE, fp)!=NULL)
    {
        match(buf, pattern);
    }
    fclose(fp);
    
    return SUCCESS;
}