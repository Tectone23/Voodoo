module dollconfig

import os
import toml
import toml.to
import logging { Exception, Warning, raise }
import json

pub struct ComponentConfig {
	filename string
	version string
	description string
	category string
	optional bool
	modified_files []map[string]string
}

pub struct Config {
	build struct {
		python_versions string
		cmake_versions string
	}
pub mut:
	components []ComponentConfig
	affected []string
}


pub fn (mut config Config) add_pulled(pulled string) {
	// Create a new component
	name := pulled.split("/")[pulled.split("/").len-1]
	component := ComponentConfig{
		filename: name
		version: '0.0.1'
		description: 'None'
		category: 'None'
		optional: true
		modified_files: [
			{"path": "./components/$name", "target": pulled}
		]
	}
	config.components << component
	config.affected << pulled
}

pub fn (config Config) pulled_exists(pulled string) bool {
	return pulled in config.affected
}

pub fn (config Config) save_config() {
	// This will write the config to a file
	conf_path := 'config.doll'

	// out_conf is the string format of our object
	out_conf_map := {
		"build": {
			"python-version": config.build.python_versions,
			"cmake-versions": config.build.cmake_versions
		}
	}

	mut output := os.create(conf_path) or {
		eprintln("Failed to recreate config")
		exit(1)
	}

	out_conf := inline_toml(config)


	output.write(out_conf.bytes()) or {
		panic("[Panic] ${err} to ${conf_path}")
	}
}

pub fn load_config() Config {
	conf_path := os.getwd() + '/config.doll'

	conf := toml.parse_file(conf_path) or {
		raise(
			&Exception{
				msg: "Failed to load config"
				source: err.msg()
				hint: "Please make sure that the current directory is a voodoo project"
			}
		)
		panic(err.msg())
	}

	// Build each module
	mut components := []ComponentConfig{}
	mut affected_paths := []string{}

	for mod in  conf.value('Component').array() {
		component := to.json(mod)
		cmp := json.decode(ComponentConfig, component) or {
			panic(err.msg())
		}
		components << cmp


		println(cmp)

		for path in cmp.modified_files {
			affected_paths << path["target"]
		}
	}

	// Construct config object
	config_obj := Config {
		struct {
			python_versions: conf.value('build.python-versions').string()
			cmake_versions: conf.value('build.cmake-versions').string()
		}
		components
		affected_paths
	}

	return config_obj
}

fn build_inline(mapper map[string]map[string]string) string {
	mut final := ""
	for title, value in mapper {
		// Check value
		for key, subvalue in value {
			final += "[[Component]]\n"
			final += "$subvalue"
		}
	}
	return final
}

fn inline_toml(conf Config) string {
	// process components
	mut components := map[string]string {}

	for component in conf.components {
		mut modified_files := ""

		if component.filename.is_blank() { continue }

		for file in component.modified_files {
			modified_files += "\t{path = \"${file["path"]}\", target = \"${file["target"]}\"},\n"
		}

		components[component.filename] = "filename = \"${component.filename}\"
version  = \"${component.version}\"
description = \"${component.description}\"
category = \"${component.category}\"
optional = \"${component.optional}\"
modified_files = [
$modified_files]

"
	}

	// Build tables
	out_conf_map := {
		"components": components
	}

	mut out := ""

	// Add build
	out += "
[build]
python-versions = \"${conf.build.python_versions}\"
cmake-versions = \"${conf.build.cmake_versions}\"

"

	// build inlines
	out += build_inline(out_conf_map)

	return out
}