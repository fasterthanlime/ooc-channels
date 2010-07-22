import threading/Thread, structs/LinkedList, os/Time

Channel: class <T> {

    mutex := Mutex new()
    queue := LinkedList<T> new()

    send: func (t: T) {
        while(queue size() > 1000) {
            Time sleepMilli(5)
        }
        mutex lock()
        queue add(t)
        mutex unlock()
    }

    recv: func -> T {
        while(true) {
            mutex lock()
            if(!queue isEmpty()) {
                val := queue removeAt(0)
                mutex unlock()
                return val
            }
            mutex unlock()
            Time sleepMilli(5)
        }
        // yay hacks
        null
    }

}

operator << <T> (c: Channel<T>, t: T) {
    c send(t)
}

operator ! <T> (c: Channel<T>) -> T {
    c recv()
}

go: func (c: Func) -> Thread {
    t := Thread new(c). start(); t
}

make: func <T> (T: Class) -> Channel<T> {
    Channel<T> new()
}

