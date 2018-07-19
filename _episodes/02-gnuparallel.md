---
title: "Simple Parallelism (GNU Parallel, R parallel and Python Multiprocessing)"
teaching: 45
exercises: 15
questions:
- "What is embarrassing parallelism?"
objectives:
- "Learn how to quickly explore parametric spaces using GNU parallel"
keypoints:
- "GNU parallel is just a tool to exploit embarrassing parallel problems.
You can equally use multiprocessing in python or R parallel libraries for the same effect."
---

## GNU Parallel

On `4.Parallel/1.BasicParallel` there is a copy of the file `output.log` used on a previous lesson.
We will use that file to mimic the creation of a parametric study involving 1000 simulations.

The command GNU parallel is very practical executing the same operation for a given list of instances.
The command will compute in parallel up to the limit of cores available or the limit given with the argument `-j`

~~~
$ seq -w 0 1000 | parallel mkdir {}
$ seq -w 0 1000 | parallel ln -s ../output.log {}
~~~
{: .source}

~~~
time grep "Time step" */output.log > /dev/null
~~~
{: .source}

~~~
seq -w 0 1000 | time parallel -j 4 grep \"Time step\" {}/output.log
~~~
{: .source}

## R in parallel

R offers one option to run some commands in parallel, the most basic form offers replacements to commands like `lapply` or `sapply` with `parLapply` and `parSapply`.

~~~
> lapply(1:3, function(x) c(x, x^2, x^3))
~~~
{: .source}

The library is called `parallel` and most embarrassing parallelism can be implemented with it.

~~~
> library(parallel)
> ncores<- detectCores()
> ncores<-4
~~~
{: .source}

~~~
> cl <- makeCluster(ncores)
> ans <- parLapply(cl, 2:4, function(x) 2^x + 3^x)
> stopCluster(cl)
~~~
{: .source}

~~~
> cl <- makeCluster(ncores)
> ans <- parSapply(cl, 2:4, function(x) 2^x + 3^x)
> stopCluster(cl)
~~~
{: .source}


~~~
RNGkind("L'Ecuyer-CMRG")
nsamples<-1e8
pois.lambda<-10
mc.reset.stream()
system.time({
  jobs<-list()
  jobs[[1]]<-mcparallel(rpois(nsamples, pois.lambda), "pois", mc.set.seed=TRUE)
  jobs[[2]]<-mcparallel(runif(nsamples), "unif", mc.set.seed=TRUE)
  jobs[[3]]<-mcparallel(rnorm(nsamples), "norm", mc.set.seed=TRUE)
  jobs[[4]]<-mcparallel(rexp(nsamples), "exp", mc.set.seed=TRUE)
  random3 <- mccollect(jobs)
})
~~~
{: .source}


## Python multiprocessing

~~~
from multiprocessing import Pool

def f(x):
    return x*x

if __name__ == '__main__':
    p = Pool(5)
    print(p.map(f, [1, 2, 3]))
~~~
{: .source}

~~~
from multiprocessing import Process

def f(name):
    print 'hello', name

if __name__ == '__main__':
    p = 10*[None]
    for i in range(10):
      p[i] = Process(target=f, args=('bob',))
      p[i].start()
      p[i].join()
~~~
{: .source}



{% include links.md %}
