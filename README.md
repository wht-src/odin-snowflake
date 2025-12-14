# Odin Snowflake

Generate Twitter like snowflake ID in Odin. These ID will never 
repeat themselves as they are time-based.

## usage
```odin
import sf "../odin_snowflake"

main :: proc() {
    gen := sf.make_generator(
        // defaults to rand.int31_max(32)
        // range [0,31]
        datacenter_id = 1, 
        // defaults to rand.int31_max(32)
        // range [0,31]
        machine_id = 1,
        // defaults to 1288834974657
        // which is twitter's default
        custom_epoch = 1288834974657,
    )
    // its on the heap, you need to free it
    defer free(gen)

    for i in 1 ..= 10 {
        flake := sf.mkflake(gen)
        fmt.println(flake)

        // convert snowflake to a bit_field
        fmt.println(sf.Snowflake(flake))
    }
}
```
