module adblib

import logging { Exception, Warning, raise }
import os

pub struct ADBConnector {}

pub fn (adb ADBConnector) get_device_list() []string {
	res := os.execute("adb devices")
	if res.exit_code != 0 {
		raise(
			&Exception{
				msg: "Failed to read device list"
				source: res.output
				hint: "Is the device attached to the host?"
			}
		) 
	}

	mut devices := []string{}

	// Go through the devices list, extract the id of the device
	for device in res.output.split("\n")[1..] {
		if !device.is_blank() {
			id := device.trim_indent().split("\t")[0]
			devices << id
		}
	}

	return devices
}

pub fn (adb ADBConnector) pull_file(target string) string {
	target_doll := adb.get_device_list()[0]
	println("Preparing to pull directory ${target} from doll ${target_doll}")

	out := "components/" + target.split("/")[target.split("/").len-1]

	res := os.execute("adb pull ${target} ${out}")
	if res.exit_code != 0 {
		raise(
			&Exception{
				msg: "Failed to use adb to pull file"
				source: res.output
				hint: "Is the device attached to the host?"
			}
		) 
	}

	println("Done!")

	return res.output
}

pub fn (adb ADBConnector) push_file(file string, target string) string {
	res := os.execute("adb push ${file} ${target}")
	if res.exit_code != 0 {
		raise(
			&Exception{
				msg: "Failed to use adb to push file ${file} to ${target}"
				source: res.output
				hint: "Please make sure that the target is writeable by your user account. You can do this via:\n`adb shell`\n`sudo chown -R phablet <target_dir>`"
			}
		) 
	}
	
	println("Pushed: ${file}")

	return res.output
}


// echo passcode | sudo -S systemctl restart lightdm
pub fn (adb ADBConnector) restart_service(passcode string, service string) {
	res := os.execute("adb exec-out \"echo ${passcode} | sudo -S systemctl restart ${service}\"")
	if res.exit_code != 0 {
		raise(
			&Exception{
				msg: "Failed to use adb to restart the service"
				source: res.output
				hint: "Please make sure the password is correct and the service exists"
			}
		) 
	}
	
	println("Restarting a service may take some time...")
	println(res.output)
}

pub fn (adb ADBConnector) get_logs(target string) []string {
	mut options := ""

	if !target.is_blank() {
		options = "-s ${target}"
	}	

	res := os.execute("adb ${options} exec-out journalctl -n 20")
	if res.exit_code != 0 {
		raise(
			&Exception{
				msg: "Failed to use adb to read logs"
				source: res.output
				hint: "Is the device attached to the host?"
			}
		) 
	}
	mut logs := []string{}

	for log in res.output.split("\n") {
		logs << log
	}

	return logs
}
