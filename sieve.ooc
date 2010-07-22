import CoroutineChannel
//import ThreadedChannel

//import os/Time

// ooc port of the Go sieve example
// http://golang.org/doc/go_tutorial.html

generate: func -> Channel<Int> {
    out := make(Int)
    go(||
        i := 2
        while(true) {
            i += 1
            //"Generate %d" printfln(i)
            out << i
        }
    )
    out
}

filter: func (in: Channel<Int>, prime: Int) -> Channel<Int> {
    out := make(Int)
    go(||
        while(true) {
            i : Int = ! in
            //"Filter (%d, %d)" printfln(i, prime)
            if(i % prime != 0) {
                out << i
            }
        }
    )
    out
}

sieve: func -> Channel<Int> {
    out := make(Int)
    go(||
        ch := generate()
        i := 1
        while (true) {
            //"Getting a prime for generator" println()
            prime : Int = ! ch
            //"Got prime %d" printfln(prime)
            out << prime
            //"Creating pipe #%d" printfln(i)
            ch = filter(ch, prime)
            i += 1
        }
    )
    out
}

main: func {
    go(||
        primes := sieve()
        while (true) {
            "%d" printfln(! primes)
        }
    ) //wait()
}