import os/Time

import CoroutineChannel
//import ThreadedChannel

main: func {

    max := 3

    hugeArray := make(Int)
    go(||
        for(i in 0..max) {
            hugeArray << i
        }
    )

    go(||
        for(i in max..(2 * max)) {
            hugeArray << i
        }
    )

    go(||
        for(i in (2 * max)..(3 * max)) {
            hugeArray << i
        }
    )

    squared := make(Int)
    go(||
        while(true) {
            i := hugeArray recv()
            squared << i * i
        }
    )

    go(||
        while(true) {
            i := ! squared
            "Got i = %d" printfln(i)
            Time sleepMilli(20)
        }
    ) //wait()

}
