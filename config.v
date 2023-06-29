module dollconfig

import os
import json

pub struct Config {
	project_path string
	config_path  string
pub mut:
	pulled_files []string // Files we sourced from the system
	pushed_files []string // Files we want to commit to the system
}

struct BaseConfigFile {
	project_name string
	project_ver  string
	pulled_files []string // Files we sourced from the system
	pushed_files []string // Files we want to commit to the system
}

pub fn (mut config Config) add_pulled(pulled string) {
	if !(pulled in config.pulled_files) {
		config.pulled_files << pulled
	} else {
		println("Didn't add pulled file to config, it already exists")
	}
}

pub fn (mut config Config) pulled_exists(pulled string) bool {
	return (pulled in config.pulled_files)
}

pub fn (config Config) save_config() {
	conf_path := 'config.doll'

	out_conf := json.encode(config)

	/*
	* We recreate the config every time.
	* This is just simpler than dealing with the
	* buffer not being cleaned properly
	* Why? idfk, ask C
	*/
	mut output := os.create(conf_path) or {
    	eprintln("Failed to recreate config")
		exit(1)
	}

	output.write(out_conf.bytes()) or {
		panic("[Panic] ${err} to ${conf_path}")
	}
}


pub fn load_config() Config {
	conf_path := os.getwd() + '/config.doll'

	source := os.read_file(conf_path) or {
		eprintln("Directory is not a project")
		exit(1)
	}

	config := json.decode(BaseConfigFile, source) or {
		panic("Invalid config supplied. It seems to be corrupt?")
	}

	return Config {
		project_path: os.getwd()
		config_path: conf_path
		pulled_files: config.pulled_files
		pushed_files: config.pushed_files
	}
}