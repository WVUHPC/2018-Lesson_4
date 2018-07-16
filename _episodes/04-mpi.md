---
title: "Distributed Computing (MPI)"
teaching: 45
exercises: 15
questions:
- "What is Message Passing Interface?"
objectives:
- "Learn how to use MPI for distribute computation even crossing nodes."
keypoints:
- "MPI is the fact standard for large scale numerical computing, where a single node no matter how big, does not have the cores or memory able to run the simulation."
---


## Introduction

MPI is a specification for the developers and users of message passing libraries.
By itself, it is NOT a library - but rather the specification of what such a
library should be.
There are several implementations of MPI, the most popular today are OpenMPI and
Intel MPI and MPICH and MVAPICH.

## Compiling MPI programs

The different implementations of MPI offer wrappers to the compilers.
The following table shows how to compile applications with several
implementations.

Using OpenMPI the compile line is as follows

| Language |	Wrapper | Command	Example |
|:---------|:---------|-----------------|
| C        | mpicc	  | mpicc [options] main.c |
| C++	     | mpicxx	  | mpicxx [options] main.cpp |
| Fortran	 | mpif90	  | mpif90 [options] main.f90 |

Using Intel MPI you can use the commands above if using GCC as underlying compiler,
or using the following commands for the intel compilers.

| Language |	Wrapper | Command	Example |
|:---------|:---------|-----------------|
| C        | mpiicc	  | mpiicc [options] main.c |
| C++	     | mpiicpc	| mpiicpc [options] main.cpp |
| Fortran	 | mpiifort	| mpiifort [options] main.f90 |

## Getting started

Lets start with one simple example showing the basic elements of the interface.
The program do actually nothing useful but illustrate the basic functions that
are common to basically any program that uses MPI.
The version in C is:

~~~
// required MPI include file  
   #include "mpi.h"
   #include <stdio.h>

   int main(int argc, char *argv[]) {
   int  numtasks, rank, len, rc;
   char hostname[MPI_MAX_PROCESSOR_NAME];

   // initialize MPI  
   MPI_Init(&argc,&argv);

   // get number of tasks
   MPI_Comm_size(MPI_COMM_WORLD,&numtasks);

   // get my rank  
   MPI_Comm_rank(MPI_COMM_WORLD,&rank);

   // this one is obvious  
   MPI_Get_processor_name(hostname, &len);
   printf ("Number of tasks= %d My rank= %d Running on %s\n", numtasks,rank,hostname);

        // do some work with message passing

   // done with MPI  
   MPI_Finalize();
   }
~~~
{: .source}

The same program in Fortran 90 follows:

~~~
program mpi_env

  ! required MPI include file                                                                                                                
  include 'mpif.h'

  integer numtasks, rank, len, ierr  
  character(MPI_MAX_PROCESSOR_NAME) hostname

  ! initialize MPI      
  call MPI_INIT(ierr)

  ! get number of tasks   
  call MPI_COMM_SIZE(MPI_COMM_WORLD, numtasks, ierr)

  ! get my rank          
  call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)

  ! this one is obvious    
  call MPI_GET_PROCESSOR_NAME(hostname, len, ierr)
  print *, 'Number of tasks=',numtasks,' My rank=',rank,' Running on=',hostname

  ! do some work with message passing

  ! done with MPI       
  call MPI_FINALIZE(ierr)

end program mpi_env
~~~
{: .source}

For the purpose of this tutorial, we will use OpenMPI, the compilation line
is as follows, for the C version:

~~~
mpicc mpi_env.c -lmpi
~~~
{: .source}

For the Fortran version:

~~~
mpif90 mpi_env.f90 -lmpi
~~~
{: .source}

Lets review the different calls.
The basic difference between the functions C and Fortran subroutines is the
integer returned.
In C the return is from the function. In Fortran the equivalent subroutine
usually contains and extra output only argument to store the value.

### MPI_Init

Initializes the MPI execution environment.
This function must be called in every MPI program, must be called before any
other MPI functions and must be called only once in an MPI program.
For C programs, MPI_Init may be used to pass the command line arguments to all
processes, although this is not required by the standard and is implementation
dependent.

~~~
MPI_Init (&argc, &argv)
MPI_INIT (ierr)
~~~
{: .source}

### MPI_Comm_size

Returns the total number of MPI processes in the specified communicator,
such as MPI_COMM_WORLD.
If the communicator is MPI_COMM_WORLD, then it represents the number of
MPI tasks available to your application.

~~~
MPI_Comm_size (comm, &size)
MPI_COMM_SIZE (comm, size, ierr)
~~~
{: .source}

### MPI_Comm_rank

Returns the rank of the calling MPI process within the specified communicator.
Initially, each process will be assigned a unique integer rank between 0
and number of tasks - 1 within the communicator MPI_COMM_WORLD.
This rank is often referred to as a task ID.
If a process becomes associated with other communicators, it will have a
unique rank within each of these as well.

~~~
MPI_Comm_rank (comm,&rank)
MPI_COMM_RANK (comm,rank,ierr)
~~~
{: .source}


### MPI_Get_processor_name

Returns the processor name.
Also returns the length of the name.
The buffer for "name" must be at least MPI_MAX_PROCESSOR_NAME characters in size.
What is returned into "name" is implementation dependent - may not be the
same as the output of the "hostname" or "host" shell commands.

~~~
MPI_Get_processor_name (&name,&resultlength)
MPI_GET_PROCESSOR_NAME (name,resultlength,ierr)
~~~
{: .source}

### MPI_Finalize

Terminates the MPI execution environment. This function should be the last MPI routine called in every MPI program - no other MPI routines may be called after it.

~~~
MPI_Finalize ()
MPI_FINALIZE (ierr)
~~~
{: .source}

## Compiling and executing a MPI program on Spruce

To compile the program you need first to load the modules

~~~
module load compilers/gcc/6.3.0 mpi/openmpi/2.0.2_gcc63
~~~
{: .bash}

To execute a MPI program is strongly suggested to run it using the queue system.
Assuming that the executable is a.out.
A minimal submission script could be:

~~~
#!/bin/sh

#PBS -N MPI_JOB
#PBS -l nodes=1:ppn=4
#PBS -l walltime=00:05:00
#PBS -m ae
#PBS -q debug
#PBS -n

module load compilers/gcc/6.3.0 mpi/openmpi/2.0.2_gcc63

cd $PBS_O_WORKDIR
mpirun -np 4 ./a.out
~~~
{: .bash}

This submission script is requesting 4 cores for running your job in one node.
Using MPI you are not constrain to use a single node, but it is always a good
idea to run the program using cores as close as possible.

## Sending Messages with Broadcasting

Lets review one classic example of MPI programming.
Many functions are computationally perform by expansions in series.
Lets use a inverse tangent series that to approximate pi.
The idea is to spread the terms of the sum among several cores, giving each of
them a range of values to work.
The C version of the code is:

~~~
#include <stdio.h>
#include <stdlib.h>
#include "mpi.h"
#include <math.h>

int main(int argc, char *argv[])
{
  int n, myid, numprocs, i;
  double PI25DT = 3.141592653589793238462643;
  double mypi, pi, h, sum, x;
  MPI_Init(&argc,&argv);
  MPI_Comm_size(MPI_COMM_WORLD, &numprocs);
  MPI_Comm_rank(MPI_COMM_WORLD, &myid);
  if (argc < 2)  {
      n=10;
    }
  else {
      n=atoi(argv[1]);
    }

  MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);
  h   = 1.0 / (double) n;
  sum = 0.0;
  printf(" Rank %d computing from %d up to %d jumping %d\n", myid,  myid+1, n, numprocs);
  for (i = myid + 1; i <= n; i += numprocs) {
    x = h * ((double)i - 0.5);
    sum += (4.0 / (1.0 + x*x));
  }
  mypi = h * sum;
  MPI_Reduce(&mypi, &pi, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
  if (myid == 0)
      printf("pi is approximately %.16f, Error is %.16e\n",
	     pi, fabs(pi - PI25DT));
  MPI_Finalize();
  return 0;
}
~~~
{: .source}

The version in Fortran 90 is:

~~~
program main
  use mpi
  double precision  pi25dt
  parameter        (pi25dt = 3.141592653589793238462643d0)
  double precision  mypi, pi, h, sum, x, f, a
  integer n, myid, numprocs, i, ierr
  character(len=32) :: arg
  ! Function to integrate
  f(a) = 4.d0 / (1.d0 + a*a)

  ! Basic initialization calls
  call mpi_init(ierr)
  call mpi_comm_rank(mpi_comm_world, myid, ierr)
  call mpi_comm_size(mpi_comm_world, numprocs, ierr)

  if (myid .eq. 0) then
     i = 0
     ierr = 1
     do
        call get_command_argument(i, arg)
        if (len_trim(arg) == 0) exit
        i = i+1
        if (i .eq. 2) then
           read(arg,*,iostat=ierr)  n

           if (ierr .ne. 0 ) then
              write(*,*) 'Conversion failed asuming n = 10 ierr=',ierr,n
              n = 10
           end if
        end if
     end do
  write(*,*) 'Splitting with N = ', n
  endif

  ! Broadcast n
  call mpi_bcast(n, 1, mpi_integer, 0, mpi_comm_world, ierr)
  ! Calculate the interval size
  h = 1.0d0/n
  sum  = 0.0d0
  write(*,*) 'Rank ', myid, 'Computing from ', myid+1, 'jumping ', numprocs
  do i = myid+1, n, numprocs
     x = h * (dble(i) - 0.5d0)
     sum = sum + f(x)
  enddo
  mypi = h * sum
  ! Collect all the partial sums
  call mpi_reduce(mypi, pi, 1, mpi_double_precision, &
       mpi_sum, 0, mpi_comm_world, ierr)
  ! Node 0 prints the answer.
  if (myid .eq. 0) then
     print *, 'pi is ', pi, ' error is', abs(pi - pi25dt)
  endif

  call mpi_finalize(ierr)
end program main
~~~
{: .source}

The compilation line is:

~~~
mpicc mpi_pi.c
~~~
{: .source}

or

~~~
mpif90 mpi_pi.f90
~~~
{: .source}

The executable expects one argument, the number of elements to perform the
integration.

~~~
mpirun -np 4 ./a.out 10000
~~~
{: .source}

There are two new functions here:

### MPI_Bcast

Data movement operation. Broadcasts (sends) a message from the process with
rank "root" to all other processes in the group.

~~~
MPI_Bcast (&buffer,count,datatype,root,comm)
MPI_BCAST (buffer,count,datatype,root,comm,ierr)
~~~
{: .source}

### MPI_Reduce

Collective computation operation. Applies a reduction operation on all tasks in the group and places the result in one task.

~~~
MPI_Reduce (&sendbuf,&recvbuf,count,datatype,op,root,comm)
MPI_REDUCE (sendbuf,recvbuf,count,datatype,op,root,comm,ierr)
~~~
{: .source}

The predefined MPI reduction operations appear below. Users can also define their own reduction functions by using the MPI_Op_create routine.

| MPI | Reduction Operation	| C Data Types | Fortran Data Type |
|:----|:--------------------|:-------------|:------------------|
| MPI_MAX	| maximum	     | integer, float	| integer, real, complex |
| MPI_MIN	| minimum	     | integer, float	| integer, real, complex |
| MPI_SUM	| sum	         | integer, float	| integer, real, complex |
| MPI_PROD | product	   | integer, float	| integer, real, complex |
| MPI_LAND | logical AND |	integer	| logical |
| MPI_BAND | bit-wise AND	| integer, MPI_BYTE	| integer, MPI_BYTE |
| MPI_LOR	 | logical OR	  | integer	| logical |
| MPI_BOR	 | bit-wise OR  | integer, MPI_BYTE	| integer, MPI_BYTE |
| MPI_LXOR | logical XOR  | integer	| logical |
| MPI_BXOR | bit-wise XOR	| integer, MPI_BYTE	| integer, MPI_BYTE |
| MPI_MAXLOC	| max value and location	| float, double and long double	real, complex, double precision |
| MPI_MINLOC	| min value and location	| float, double and long double	real, complex, double precision |


{% include links.md %}
