
variable "cpus" {
  type    = string
  default = "1"
}

variable "disk_size" {
  type    = string
  default = "10240"
}

variable "iso_checksum" {
  type    = string
  default = "ce507d7f8a0da796339b86705a539d0d9eef5f19eebb1840185ce64be65e7e07"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_download_url" {
  type    = string
  default = "http://dl-cdn.alpinelinux.org/alpine/v3.16/releases/x86_64/alpine-virt-3.16.1-x86_64.iso"
}

variable "iso_local_url" {
  type    = string
  default = "../../iso/alpine-virt-3.16.1-x86_64.iso"
}

variable "memory" {
  type    = string
  default = "1024"
}

variable "root_password" {
  type    = string
  default = "vagrant"
}

variable "ssh_key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
}

variable "ssh_password" {
  type    = string
  default = "vagrant"
}

variable "ssh_username" {
  type    = string
  default = "vagrant"
}

variable "vm_name" {
  type    = string
  default = "alpine-3.16.1-x86_64"
}

source "virtualbox-iso" "virtualbox-iso" {
  boot_command         = [
	"root<enter><wait>",
	"ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
	"wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers<enter><wait>",
	"setup-apkrepos -1<enter><wait5>",
	"ERASE_DISKS='/dev/sda' setup-alpine -f $PWD/answers<enter><wait5>",
	"${var.ssh_password}<enter><wait>",
	"${var.ssh_password}<enter><wait5><enter><wait>",
	"mount /dev/sda3 /mnt<enter>",
	"echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter>",
	"umount /mnt ; reboot<enter>"
	]
  boot_wait            = "10s"
  communicator         = "ssh"
  disk_size            = "${var.disk_size}"
  format               = "ova"
  guest_additions_mode = "disable"
  guest_os_type        = "Linux26_64"
  headless             = false
  http_directory       = "http"
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_urls             = ["${var.iso_local_url}", "${var.iso_download_url}"]
  keep_registered      = "false"
  shutdown_command     = "/sbin/poweroff"
  ssh_password         = "${var.ssh_password}"
  ssh_timeout          = "10m"
  ssh_username         = "root"
  vboxmanage           = [
	[ "modifyvm", "{{ .Name }}", "--memory", "${var.memory}" ],
	[ "modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}" ],
	[ "modifyvm", "{{ .Name }}", "--rtcuseutc", "on" ],
	[ "modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga" ],
	[ "modifyvm", "{{ .Name }}", "--vram", "6" ],
	[ "modifyvm", "{{ .Name }}", "--vrde", "off" ]
	]
  vm_name              = "${var.vm_name}"
}

build {
  description = "Build base Alpine Linux x86_64"

  sources = ["source.virtualbox-iso.virtualbox-iso"]

  provisioner "shell" {
    inline = [
	"echo http://dl-cdn.alpinelinux.org/alpine/v3.16/community >> /etc/apk/repositories",
	"apk update",
	"apk add sudo",
	"apk add virtualbox-guest-additions",
	"echo '%wheel ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/wheel",
	"user=${var.ssh_username}",
	"echo Add user $user with NOPASSWD sudo",
	"adduser $user --disabled-password",
	"echo '${var.ssh_username}:${var.ssh_password}' | chpasswd",
	"adduser $user wheel",
	"echo add ssh key",
	"cd ~${var.ssh_username}",
	"mkdir .ssh",
	"chmod 700 .ssh",
	"echo ${var.ssh_key} > .ssh/authorized_keys",
	"chown -R $user .ssh",
	"echo disable ssh root login",
	"sed '/PermitRootLogin yes/d' -i /etc/ssh/sshd_config"
	]
  }

}
