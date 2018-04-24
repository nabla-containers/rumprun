#define _MULTI_THREADED
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

void foo(void);  /* Functions that use the TLS data */
void bar(void);
 
#define checkResults(string, val) {             \
 if (val) {                                     \
   printf("Failed with %d at %s", val, string); \
   exit(1);                                     \
 }                                              \
}
 
#define                 NUMTHREADS   1

typedef struct {
   int   data1;
   int   data2;
} threadparm_t; 

static pthread_key_t thrnumkey1;
static pthread_key_t thrnumkey2;
static pthread_key_t thrnumkey3;


void *theThread(void *parm)
{
   int               rc;
   unsigned long long i;
   threadparm_t     *gData;

   gData = (threadparm_t *)parm;
   int id = gData->data1;
   pthread_setspecific(thrnumkey1, 0);

   for (i=0;i<200000000;i++) {
       int sum = pthread_getspecific(thrnumkey1);
       pthread_setspecific(thrnumkey1, ++sum);
       //printf("Thread %d: Entered %d\n", id, sum);
       sched_yield();
   }
   return NULL;
}
 
void foo() {
   bar();
}
 
void bar() {
   //pthread_yield();
   usleep(1);
   return;
}
 

int main(int argc, char **argv)
{
  pthread_t             thread[NUMTHREADS];
  int                   rc=0;
  int                   i;
  threadparm_t          gData[NUMTHREADS];
 
  pthread_key_create(&thrnumkey1, NULL);
  pthread_key_create(&thrnumkey2, NULL);
  pthread_key_create(&thrnumkey3, NULL);

  printf("Enter Testcase - %s\n", argv[0]);
 
  printf("Create/start threads\n");
  for (i=0; i < NUMTHREADS; i++) { 
     /* Create per-thread TLS data and pass it to the thread */
     gData[i].data1 = i;
     gData[i].data2 = (i+1)*2;
     rc = pthread_create(&thread[i], NULL, theThread, &gData[i]);
     checkResults("pthread_create()\n", rc);
  }
 
  printf("Wait for the threads to complete, and release their resources\n");
  for (i=0; i < NUMTHREADS; i++) {
     rc = pthread_join(thread[i], NULL);
     checkResults("pthread_join()\n", rc);
  }

  printf("Main completed\n");
  return 0;
}
