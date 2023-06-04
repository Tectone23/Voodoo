module logging

pub struct Exception {
	msg string
	source string
	line int
	hint string
	@type string = "e"
}

pub struct Warning {
	msg string
	source string
	line int
	hint string
	@type string = "w"
}

type Either = Exception | Warning

pub fn raise(e Either) {
	if e.@type == "e" {
		println("\033[31;1;4m[Exception] => ${e.msg}\033[0m")
		println("\033[32;49;3m\t${e.source}\033[0m")
		if e.hint.len != 0 {
			println("\033[36;49;3m${e.hint}\033[0m")
		}
		exit(1)
	} else {
		println("\033[33;4;1m[Warning] => ${e.msg}\033[0m")
		println("\033[32;49;3m\t${e.source}\033[0m")
		if e.hint.len != 0 {
			println("\033[36;49;3m${e.hint}\033[0m")
		}
	}
}