package odin_snowflake

import "core:fmt"
import "core:math/rand"
import "core:time"

Snowflake_Generator :: struct {
	// last epoch when a flake is generated
	last_time:     u64,
	seq_id:        u16,
	// [0, 31]
	datacenter_id: u8,
	// [0, 31]
	machine_id:    u8,
	// max 41 bits
	custom_epoch:  u64,
}

Snowflake :: bit_field u64 {
	// for every ID generated on process,
	// sequence number increments by 1 
	// number is reset to 0 every millisecond
	sequence_number: u16  | 12,
	// machine id, max 32 machines per datacenter
	machine_id:      u8   | 5,
	// datacenter id, max 32 datacenters
	datacenter_id:   u8   | 5,
	// millseconds since the epoch or custom epoch
	timestemp:       u64  | 41,
	// sign bit will always be 0
	sign_bit:        bool | 1,
}

current_milli_epoch :: proc() -> u64 {
	return u64(time.time_to_unix_nano(time.now()) / 1_000_000)
}

// make a snowflake generator on the heap
make_generator :: proc(
	datacenter_id: Maybe(u8) = nil,
	machine_id: Maybe(u8) = nil,
	// we use twitter's as default epoch
	// going somewhat lower causes overflow
	custom_epoch: u64 = 1288834974657,
) -> ^Snowflake_Generator {
	gen := new(Snowflake_Generator)

	gen.last_time = current_milli_epoch()

	if datacenter_id, ok := datacenter_id.?; ok {
		assert(0 <= datacenter_id && datacenter_id <= 31)
		gen.datacenter_id = datacenter_id
	} else {
		gen.datacenter_id = u8(rand.int31_max(32))
	}
	if machine_id, ok := machine_id.?; ok {
		assert(0 <= machine_id && machine_id <= 31)
		gen.machine_id = machine_id
	} else {
		gen.machine_id = u8(rand.int31_max(32))
	}
	gen.custom_epoch = custom_epoch

	return gen
}

mkflake :: proc(generator: ^Snowflake_Generator) -> u64 {
	flake := Snowflake{}

	// to millisecond epoch
	now := current_milli_epoch()

	if now == generator.last_time {
		flake.sequence_number = generator.seq_id
		generator.seq_id += 1
	} else {
		generator.last_time = now
		generator.seq_id = 0
	}

	timestemp := now - generator.custom_epoch
	assert(0 <= timestemp && timestemp <= 1099511627775)
	flake.timestemp = now - generator.custom_epoch
	flake.machine_id = generator.machine_id
	flake.datacenter_id = generator.datacenter_id

	return transmute(u64)(flake)
}

main :: proc() {
	fmt.println("the current time is", current_milli_epoch())
	gen := make_generator(datacenter_id = 1, machine_id = 1)
	defer free(gen)

	for i in 1 ..= 100 {
		flake := mkflake(gen)
		fmt.println(flake)
		// fmt.printfln("%b", flake)
		// fmt.println(Snowflake(flake))
	}
}
