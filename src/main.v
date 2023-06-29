module main

/*
	Imports:

	flag - For cli args
	os 	 - Args
*/

import flag
import os
import logging { Exception, Warning, raise }
import adblib { ADBConnector }
import dollconfig { Config, load_config }

fn main() {
	mut fp := flag.new_flag_parser(os.args)

	fp.application("voodoo")
	fp.version("0.0.3")
	fp.description(
		'Voodoo - V|oo|-do|o| a change to the doll system\n' +
		'Manipulate an UT system like a voodoo doll'
	)
	fp.skip_executable()

	source := fp.string('source', `s`, '', 'specify project source')
	target := fp.string('target', `t`, '', 'specify a target doll')
	pull   := fp.string('pull', `p`, '', 'specify path to pull from target')
	passcode := fp.string('passcode', `w`, '', 'device passcode')
	restart_service := fp.string('restart_service', `r`, '', 'restart a specific service')
	publish := fp.bool('publish', `u`, false, 'publish project to device')
	new    := fp.bool('new', `n`, false, 'create new project from doll device path')
	list   := fp.bool('dolls', `d`, false, 'list all attached doll devices')
	shorthand := fp.bool('short', `z`, false, 'enable shorthand syntax for use in scripts')
	debug  := fp.bool('debug', `d`, false, 'enable debugging')
	logs   := fp.bool('logs', `l`, false, 'show device logs')
	symlink := fp.bool('symlink', `v`, false, 'symlink voodoo to use systemwide')
	spook := fp.bool('spook', `_`, false, 'does spooky things')

	fp.finalize() or {
		eprintln(err.msg())
		exit(1)
	}

	// Create ADB connector
	adb := ADBConnector {}

	// Ensure device is attached
	device_attached := adb.get_device_list().len > 0

	if new {
		// Create a new project
		os.mkdir_all("components") or {
			eprintln("Unable to create directories!")
			exit(1)
		}
		mut output := os.create('config.doll') or {
    		os.open('config.doll') or {
				eprintln("Unable to create configuration file!")
				exit(1)
			}
		}
		output.write(
			'[build]
python-versions = ">=3.8"
cmake-versions = "3.22.1"'.bytes()
		)!
	} else

	if !restart_service.is_blank() {
		if !device_attached { raise(&Exception{
			msg: "No device detected"
			source: "restart_service"
			hint: "Is the device attached to the host?"
		}) }

		if passcode.is_blank() {
			println("Please provide a passcode as well")
			exit(1)
		}

		adb.restart_service(passcode, restart_service)
		exit(1)
	}

	if !pull.is_blank() {
		if !device_attached { raise(&Exception{
			msg: "No device detected"
			source: "restart_service"
			hint: "Is the device attached to the host?"
		}) }

		// Check if the current directory is a project
		// And load the config
		mut config := load_config()

		// Check if file already exists, ask whether the user wants us to overwrite
		if config.pulled_exists(pull) {
			confirm := os.input("Pulled file exists, overwrite? [y/*] ")
			if confirm != 'y' {
				exit(0)
			}
		}

		// File for example usage: /usr/share/lomiri/Greeter/Clock.qml
		adb.pull_file(pull)

		// We need to add this pull information into the project config file
		config.add_pulled(pull)

		config.save_config()
	} else

	if publish {
		if !device_attached { raise(&Exception{
			msg: "No device detected"
			source: "restart_service"
			hint: "Is the device attached to the host?"
		}) }
		// Check if the current directory is a project
		// And load the config
		mut config := load_config()

		// Now we are going to go through every file and push it

		// for file in config.pulled_files {
		// 	current_file := file.split("/")[file.split("/").len-1]
		//
		// 	adb.push_file("components/"+current_file, file)
		// }

	} else
	
	if list {
		if debug { println("[Main] Contact adb for device list") }
		dolls := adb.get_device_list()
		
		// Display dolls, use shorthand by default
		if !shorthand { println("Dolls attached to host:") }
		for doll in dolls {
			if shorthand { println(doll) }
			else { println("doll: ${doll}") }
		}
	} else

	if logs {
		if !device_attached { raise(&Exception{
			msg: "No device detected"
			source: "restart_service"
			hint: "Is the device attached to the host?"
		}) }
		if debug { println("[Main] Using ADBConnector to receive logs. Command executed is `adb exec-out journalctl -n 20`") }
		for l in adb.get_logs(target) {
			println(l)
		}
	} else

	if symlink {
		mut link_path := ""
		link_dir := '/usr/local/bin'
		if !os.exists(link_dir) {
			os.mkdir_all(link_dir) or { panic(err) }
		}
		origin := os.getwd() + '/voodoo'
		link_path = link_dir + '/voodoo'
		if debug { println("[Main] Going to try and symlink ${origin} to ${link_path}") }

		os.symlink(origin, link_path) or {
			eprintln('Failed to create symlink "${link_path}" to "${origin}". Try again with sudo. If that *still* doesnt work, please make a manual soft link')
			exit(1)
		}
	} else

	if !source.is_blank() && !os.exists(source) {
		eprintln("Project source path does not exist or wasnt specified!")
		exit(1)
	} else 


	if spook {
		println(
'
      |\\      _,,,---,,_
ZZZzz /,`.-\'`\'    -.  ;-;;,_
     |,4-  ) )-,_. ,\\ (  `\'-\'
    \'---\'\'(_/--\'  `-\'\\_)  

Credit - Felix Lee 
')
	} else

	{
		println("No action specified")
	}

}