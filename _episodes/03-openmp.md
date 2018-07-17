---
title: "Multithreading (OpenMP)"
teaching: 45
exercises: 15
questions:
- "What is OpenMP?"
objectives:
- "Learn how to create parallel loops with minimal changes to your code."
keypoints:
- "Both GCC and Intel compilers offer OpenMP support. Loops can be processed in parallel if there is no data dependency between each iteration of the loop."
---

# Parallel Programming with OpenMP

OpenMP is an Application Program Interface (API) that provides a portable, scalable model for developers of shared memory parallel applications.
OpenMP works with Symmetric Multiprocessing (SMP)
The API supports C/C++ and Fortran on a wide variety of architectures.
This tutorial covers some of the major features of OpenMP 4.0, including its various constructs and directives for specifying parallel regions, work sharing, synchronization and data environment.
Runtime library functions and environment variables are also covered.
This tutorial includes both C and Fortran example codes and a lab exercise.

## What is a Symmetric Multiprocessing (SMP)?

Most computers today have several cores, that is also true for the individual nodes on a cluster.
The several cores in a node have access to the main memory of the machine.
When several processing units see the same memory we say that that machine is a SMP system.
Most multiprocessor systems today use an SMP architecture.
Symmetric multiprocessing (SMP) involves a multiprocessor computer hardware and software architecture where two or more identical processors are connected to a single, shared main memory, have full access to all I/O devices, and are controlled by a single operating system instance that treats all processors equally.

<a href="https://upload.wikimedia.org/wikipedia/commons/1/1c/SMP_-_Symmetric_Multiprocessor_System.svg">
  <img src="https://upload.wikimedia.org/wikipedia/commons/1/1c/SMP_-_Symmetric_Multiprocessor_System.svg" alt="SMP" />
</a>

## What is OpenMP

OpenMP is an implementation of multithreading, a method of parallelizing whereby a master thread (a series of instructions executed consecutively) forks a specified number of slave threads and the system divides a task among them. The threads then run concurrently, with the runtime environment allocating threads to different processors.

The core elements of OpenMP are the constructs for thread creation, workload distribution (work sharing), data-environment management, thread synchronization, user-level runtime routines and environment variables.

In C/C++, OpenMP uses #pragmas. Those instructions are comments to the non openmp compiler but can be understood if the compiler support them and if the compilation line includes instructions to include openmp in the final object.
In Fortran OpenMP uses comments like "!$omp", they are also comments in Fortran 90+ but can be used by the compiler if the compilation arguments are included.

<a href="https://upload.wikimedia.org/wikipedia/commons/9/9b/OpenMP_language_extensions.svg">
  <img src="https://upload.wikimedia.org/wikipedia/commons/9/9b/OpenMP_language_extensions.svg" alt="OpenMP" />
</a>

## First example

Lets create a very simple example in C. Lets call it "omp_simple.c"

~~~
#include <stdio.h>

int main(int argc, char *argv[])
{
#pragma omp parallel
  printf("This is a thread.\n");
  return 0;
}
~~~
{: .source}

~~~
gcc -fopenmp omp_simple.c
~~~
{: .bash}

Executing the executable "a.out" will produce:

~~~
This is a thread.
This is a thread.
This is a thread.
This is a thread.
...
~~~
{: .output}

The actual number of threads is based on the number of cores available on the
machine. However, you can control that number changing the environmental variable
"OMP_NUM_THREADS"

~~~
OMP_NUM_THREADS=3 ./a.out
~~~
{: .bash}

Similarly, the fortran version of the same program is

~~~
program hello

  !$omp parallel
  print *, 'This is a thread'
  !$omp end parallel

end program hello
~~~
{: .source}

~~~
gfortran -fopenmp omp_simple.f90
~~~
{: .source}

And executed like
~~~
OMP_NUM_THREADS=3 ./a.out
~~~
{: .bash}

## A parallel loop

Now its time to a more useful and complex example.
One of the typical cases where OpenMP offers advantages is doing
Single Instruction Multiple Data (SIMD) operations.
For example, if you want to compute the dot product of two vectors, you are
doing the same operation, multiplying two numbers, for all the indices of
the vectors. As both vectors are on the same memory space that all cores can see,
the operation can be easily compute concurrently, by giving each core a chunk
of the vector and storing the result on another one also shared by all cores.
Lets see the example of that.
The C version looks like this:

~~~
#include <omp.h>
#include <stdio.h>
#define N 10000
#define CHUNKSIZE 100

int main(int argc, char *argv[]) {

  int i, chunk;
  float a[N], b[N], c[N];

  /* Initializing vectors */
  for (i=0; i < N; i++)
    {
      a[i] = i;
      b[i] = i * N;
    }
  chunk = CHUNKSIZE;

#pragma omp parallel shared(a,b,c,chunk) private(i)
  {
#pragma omp for schedule(dynamic,chunk)
    for (i=0; i < N; i++)
      c[i] = a[i] + b[i];
  }   /* end of parallel region */

  for (i=0; i < 10; i++) printf("%17.1f %17.1f %17.1f\n", a[i], b[i], c[i]);
  printf("...\n");
  for (i=N-10; i < N; i++)  printf("%17.1f %17.1f %17.1f\n", a[i], b[i], c[i]);
}
~~~
{: .source}

And the fortran version is:

~~~
program omp_vec_addition

  integer n, chunksize, chunk, i
  parameter (n=10000)
  parameter (chunksize=100)
  real a(n), b(n), c(n)

  !initialization of vectors
  do i = 1, n
     a(i) = i
     b(i) = a(i) * n
  enddo
  chunk = chunksize

  !$omp parallel shared(a,b,c,chunk) private(i)

  !$omp do schedule(dynamic,chunk)
  do i = 1, n
     c(i) = a(i) + b(i)
  enddo
  !$omp end do

  !$omp end parallel

  do i = 1, 10
     write(*,'(3F17.1)') a(i), b(i), c(i)
  end do
  write(*,*) '...'
  do i = 1, 10
      write(*,'(3F17.1)') a(n-10+i), b(n-10+i), c(n-10+i)
  end do

end program omp_vec_addition
~~~
{: .source}

Notice that we have declare that vectors a, b and c are shared; the different
threads are actually reading and writing on the same memory.
Each thread, however, keeps a private copy of i as each value will change and the
loop will be run for different threads for different chunks.

The instruction "dynamic" indicates that each thread will receive a new chunk
everytime it completes the previous one. The size of the chunk is determined by
the variabl "chunk" and for this example is set to 100.

## Concurrent sections

Spliting loops with SIMD operations is one of the most common ways.
However, OpenMP offers several other functionalities for parallel programming.
One of them is declaring sections of code that can be run concurrently and
instruct the compiler to create separate threads for each of them.

The SECTIONS directive specifies that the enclosed sections of code are to be
divided among the threads in the team.
Independent SECTION directives are group within a SECTIONS directive.
Each SECTION is executed once by a thread in the team.
Different sections may be executed by different threads.
If there are more threads than sections, some threads will not execute a
section and some will.

Lets see than with an example, the code in C.

~~~
#include <stdio.h>
#include <omp.h>
#define N 10000

int main(int argc, char *argv[]) {

  int i, tid;
  float a[N], b[N], c[N], d[N];

  /* Some initializations */
  for (i=0; i < N; i++) {
    a[i] = i * i;
    b[i] = i + i;
  }

#pragma omp parallel shared(a,b,c,d) private(i, tid)
  {
    tid=omp_get_thread_num();

#pragma omp sections nowait
    {

#pragma omp section
      {
      printf("Thread: %d working on + section\n", tid);
      for (i=0; i < N; i++)
	c[i] = a[i] + b[i];
      }

#pragma omp section
      {
      printf("Thread: %d working on * section\n", tid);
      for (i=0; i < N; i++)
	d[i] = a[i] * b[i];
      }

    }  /* end of sections */

  }  /* end of parallel region */

  for (i=0; i < 10; i++) printf("%17.1f %17.1f %17.1f %17.1f\n", a[i], b[i], c[i], d[i]);
  printf("...\n");
  for (i=N-10; i < N; i++)  printf("%17.1f %17.1f %17.1f %17.1f\n", a[i], b[i], c[i], d[i]);
}
~~~
{: .source}

The almost equivalent version if fortran will be:

~~~
program vec_add_sections

  integer n, i, tid, omp_get_thread_num
  parameter (n=10000)
  real a(n), b(n), c(n), d(n)

  !some initializations
  do i = 1, n
     a(i) = i * i
     b(i) = i + i
  enddo

  !$omp parallel shared(a,b,c,d), private(i, tid)
  tid=omp_get_thread_num()

  !$omp sections

  !$omp section
  write(*,*) 'Thread: ', tid, ' working on + section'
  do i = 1, n
     c(i) = a(i) + b(i)
  enddo

  !$omp section
  write(*,*) 'Thread: ', tid, ' working on * section'
  do i = 1, n
     d(i) = a(i) * b(i)
  enddo

  !$omp end sections nowait

  !$omp end parallel

  do i = 1, 10
     write(*,'(4f17.1)') a(i), b(i), c(i), d(i)
  end do
  write(*,*) '...'
  do i = 1, 10
     write(*,'(4f17.1)') a(n-10+i), b(n-10+i), c(n-10+i), d(n-10+i)
  end do

end program vec_add_sections
~~~
{: .source}

In this example we have created two sections. If your OMP_NUM_THREADS is larger
than 2, the other threads will still exists but no work will be allocated to them.

## Collecting partial results.

Sometimes the result of the operation needs to be accumulated on a single
variable. You could eventually create and array to store partial results, but
OpenMP offers also the possibility of a shared variable that is not rewritten but
accumulated by several threads working on it.
Let see than on a basic example of the dot product.
The C version:

~~~
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

# define N 10

int main(int argc, char *argv[])  {

  int   i, chunk;
  float a[N], b[N], result;

  /* Some initializations */
  chunk = 10;
  result = 0.0;
  for (i=0; i < N; i++) {
    a[i] = drand48();
    b[i] = drand48();
  }

  for (i=0; i < N; i++)
    printf("%17.3f %17.3f\n", a[i], b[i]);

#pragma omp parallel for       \
  default(shared) private(i)   \
  schedule(static,chunk)       \
  reduction(+:result)

  for (i=0; i < N; i++)
    result = result + (a[i] * b[i]);

 printf("Dot Product dot(a,b) = %f\n",result);
}
~~~
{: .source}

The Fortran version:

~~~
program dot_product

  integer n, chunksize, chunk, i, nn
  parameter (n=10)
  parameter (chunksize=10)
  real a(n), b(n), result

  integer, allocatable :: seed(:)

  call random_seed(size = nn)
  allocate(seed(nn))
  seed(:)=0.0
  call random_seed(put=seed)

  !some initializations
  !$omp  parallel do &
  !$omp  default(shared) private(i)
  do i = 1, n
     call random_number(a(i))
     call random_number(b(i))
  enddo
  !$omp  end parallel do

  do i = 1, n
     write(*,'(2F17.3)') a(i),b(i)
  end do

  result= 0.0
  chunk = chunksize

  !$omp  parallel do &
  !$omp  default(shared) private(i) &
  !$omp  schedule(static,chunk) &
  !$omp  reduction(+:result)
  do i = 1, n
     result = result + (a(i) * b(i))
  enddo
  !$omp  end parallel do

  print *, 'Dot product of dot(a,b) = ', result
end program dot_product
~~~
{: .source}

## Runtime Library functions

There are a number of functions that can be called from the openmp library.
This is summary of some of them:


| routine              | purpose |
|:---------------------|:--------|
| omp_set_num_threads  |   sets the number of threads that will be used in the next parallel region |
| omp_get_num_threads  |   returns the number of threads that are currently in the team executing the parallel region from which it is called |
| omp_get_max_threads  |   returns the maximum value that can be returned by a call to the omp_get_num_threads function |
| omp_get_thread_num   |   returns the thread number of the thread, within the team, making this call |
| omp_get_thread_limit |   returns the maximum number of openmp threads available to a program |
| omp_get_num_procs    |   returns the number of processors that are available to the program |
| omp_in_parallel      |   used to determine if the section of code which is executing is parallel or not |
| omp_set_dynamic      |   enables or disables dynamic adjustment (by the run time system) of the number of threads available for execution of parallel regions |
| omp_get_dynamic      |   used to determine if dynamic thread adjustment is enabled or not |
| omp_set_nested       |   used to enable or disable nested parallelism |
| omp_get_nested       |   used to determine if nested parallelism is enabled or not |
| omp_set_schedule     |   sets the loop scheduling policy when "runtime" is used as the schedule kind in the openmp directive |
| omp_get_schedule     |   returns the loop scheduling policy when "runtime" is used as the schedule kind in the openmp directive |
| omp_set_max_active_levels   |    sets the maximum number of nested parallel regions |
| omp_get_max_active_levels   |    returns the maximum number of nested parallel regions |
| omp_get_level               |    returns the current level of nested parallel regions |
| omp_get_ancestor_thread_num |    returns, for a given nested level of the current thread, the thread number of ancestor thread |
| omp_get_team_size           |    returns, for a given nested level of the current thread, the size of the thread team |
| omp_get_active_level        |    returns the number of nested, active parallel regions enclosing the task that contains the call |
| omp_in_final                |    returns true if the routine is executed in the final task region; otherwise it returns false |
| omp_init_lock               |    initializes a lock associated with the lock variable |
| omp_destroy_lock            |    disassociates the given lock variable from any locks |
| omp_set_lock                |    acquires ownership of a lock |
| omp_unset_lock              |    releases a lock |
| omp_test_lock               |    attempts to set a lock, but does not block if the lock is unavailable |
| omp_init_nest_lock          |    initializes a nested lock associated with the lock variable |
| omp_destroy_nest_lock       |    disassociates the given nested lock variable from any locks |
| omp_set_nest_lock           |    acquires ownership of a nested lock |
| omp_unset_nest_lock         |    releases a nested lock |
| omp_test_nest_lock          |    attempts to set a nested lock, but does not block if the lock is unavailable |
| omp_get_wtime               |    provides a portable wall clock timing routine |
| omp_get_wtick               |    returns a double-precision floating point value equal to the number of seconds between successive clock ticks |
|:---------------------|-----------|

When using those runtime calls in C/C++ you need to import "omp.h".

> ## Challenge
>
> Create a program  that get the maximum number of threads and use
> "omp_set_num_threads" to create loops with increasing number of threads up to
> the limit imposed by omp_get_max_threads.
>
{: .challenge}

## Where to go from here

The OpenMP webpage is [OpenMP](http://www.openmp.org "OpenMP") offers several
resources. Several examples are available at
[OpenMP Github page](https://github.com/OpenMP/Examples).

This lesson is loosely based on a similar one from
[Lawrence Livermore National Laboratory](https://computing.llnl.gov/tutorials/openMP)


{% include links.md %}
